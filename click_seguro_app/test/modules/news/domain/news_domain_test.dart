import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_filter.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_categories_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_feed_page_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_feed_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_news_detail_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_news_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_saved_news_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/mark_news_as_read_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/entities/like_result_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reels_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_reels_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/toggle_like_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/toggle_save_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../fakes/fake_news_repository.dart';

void main() {
  group('NewsFilter', () {
    test('busca sem espaços nas pontas', () {
      expect(const NewsFilter(search: '  pix ').normalizedSearch, 'pix');
    });

    test('hasSearch só com 2 caracteres ou mais', () {
      expect(const NewsFilter(search: 'p').hasSearch, isFalse);
      expect(const NewsFilter(search: ' p ').hasSearch, isFalse);
      expect(const NewsFilter(search: 'pi').hasSearch, isTrue);
    });

    test('isEmpty sem categoria e sem busca útil', () {
      expect(const NewsFilter().isEmpty, isTrue);
      expect(const NewsFilter(search: 'p').isEmpty, isTrue);
      expect(const NewsFilter(categorySlug: 'phishing').isEmpty, isFalse);
      expect(const NewsFilter(search: 'pix').isEmpty, isFalse);
    });

    test('igualdade por valor (busca normalizada)', () {
      expect(
        const NewsFilter(categorySlug: 'phishing', search: 'pix '),
        const NewsFilter(categorySlug: 'phishing', search: 'pix'),
      );
      expect(
        const NewsFilter(categorySlug: 'phishing'),
        isNot(const NewsFilter()),
      );
    });

    test('copyWith troca ou limpa a categoria', () {
      const filter = NewsFilter(categorySlug: 'phishing', search: 'pix');

      expect(filter.copyWith(search: 'golpe').search, 'golpe');
      expect(filter.copyWith(search: 'golpe').categorySlug, 'phishing');
      expect(filter.copyWith(clearCategory: true).categorySlug, isNull);
      expect(
        filter.copyWith(categorySlug: 'golpes-bancarios').categorySlug,
        'golpes-bancarios',
      );
    });
  });

  group('appendUnique', () {
    test('acrescenta só ids novos, na ordem', () {
      final (items, added) = newsItems(3).appendUnique([
        newsItem('n2'),
        newsItem('n4'),
        newsItem('n4'),
        newsItem('n5'),
      ]);

      expect(items.map((n) => n.id), ['n1', 'n2', 'n3', 'n4', 'n5']);
      expect(added, 2);
    });

    test('página repetida não acrescenta nada', () {
      final (items, added) = newsItems(2).appendUnique(newsItems(2));

      expect(items, hasLength(2));
      expect(added, 0);
    });
  });

  group('usecases repassam ao repository', () {
    late FakeNewsRepository repository;

    setUp(() => repository = FakeNewsRepository());

    test('GetFeedUseCase', () async {
      final result = await GetFeedUseCase(repository)();

      expect(result.isRight(), isTrue);
      expect(repository.feedCalls, 1);
    });

    test('GetFeedPageUseCase', () async {
      repository.feedPages[2] = Right(
        NewsPageEntity(items: newsItems(1), hasMore: false, page: 2),
      );

      final result = await GetFeedPageUseCase(repository)(2);

      expect(repository.feedPageCalls, [2]);
      expect(result.getRight().toNullable()!.page, 2);
    });

    test('GetNewsUseCase', () async {
      const filter = NewsFilter(categorySlug: 'phishing');

      await GetNewsUseCase(repository)(filter, 3);

      expect(repository.newsCalls.single.filter, filter);
      expect(repository.newsCalls.single.page, 3);
    });

    test('GetCategoriesUseCase devolve a falha do repository', () async {
      repository.categoriesResult = const Left(ConnectionFailure());

      final result = await GetCategoriesUseCase(repository)();

      expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
    });
  });

  group('Reels (specs/008)', () {
    late FakeNewsRepository repository;

    setUp(() => repository = FakeNewsRepository());

    test('ReelEntity.copyWith troca só o pedido', () {
      final original = reel('r1', likesCount: 3, isSaved: true);

      final liked = original.copyWith(isLiked: true, likesCount: 4);

      expect(liked.id, 'r1');
      expect(liked.isLiked, isTrue);
      expect(liked.likesCount, 4);
      expect(liked.isSaved, isTrue);
      expect(liked.content, original.content);
      expect(original.isLiked, isFalse);
    });

    test('appendUniqueReels não repete id', () {
      final (merged, added) = [
        reel('r1'),
        reel('r2'),
      ].appendUniqueReels([reel('r2'), reel('r3')]);

      expect(merged.map((r) => r.id), ['r1', 'r2', 'r3']);
      expect(added, 1);
    });

    test('GetReelsUseCase repassa o cursor', () async {
      repository.reelsResults['c2'] = Right(
        ReelsPageEntity(items: [reel('r5')], nextCursor: null),
      );

      final result = await GetReelsUseCase(repository)(cursor: 'c2');

      expect(
        result.getOrElse((_) => throw StateError('')).items.single.id,
        'r5',
      );
      expect(repository.reelsCalls, ['c2']);
    });

    test('ToggleLikeUseCase e ToggleSaveUseCase repassam o id', () async {
      repository.likeResults.add(
        const Right(LikeResultEntity(liked: true, likesCount: 1)),
      );
      repository.saveResults.add(const Left(ConnectionFailure()));

      final like = await ToggleLikeUseCase(repository)('n1');
      final save = await ToggleSaveUseCase(repository)('n2');

      expect(like.getOrElse((_) => throw StateError('')).liked, isTrue);
      expect(save.getLeft().toNullable(), isA<ConnectionFailure>());
      expect(repository.likeCalls, ['n1']);
      expect(repository.saveCalls, ['n2']);
    });
  });

  group('detalhe e salvas (specs/010)', () {
    late FakeNewsRepository repository;

    setUp(() => repository = FakeNewsRepository());

    test('GetNewsDetailUseCase repassa o id', () async {
      final result = await GetNewsDetailUseCase(repository)('n7');

      expect(result.getRight().toNullable()!.detail.id, 'n7');
      expect(repository.detailCalls, ['n7']);
    });

    test('MarkNewsAsReadUseCase repassa o id e a falha', () async {
      repository.readResults.add(const Left(ConnectionFailure()));

      final result = await MarkNewsAsReadUseCase(repository)('n7');

      expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
      expect(repository.readCalls, ['n7']);
    });

    test('GetSavedNewsUseCase repassa a página', () async {
      final result = await GetSavedNewsUseCase(repository)(3);

      expect(result.isRight(), isTrue);
      expect(repository.savedCalls, [3]);
    });

    test('hasSource: só endereço http(s)', () {
      expect(newsDetail('n1').hasSource, isTrue);
      expect(
        newsDetail('n1', sourceUrl: 'http://fonte.test').hasSource,
        isTrue,
      );
      expect(newsDetail('n1', sourceUrl: '').hasSource, isFalse);
      expect(
        newsDetail('n1', sourceUrl: 'ftp://fonte.test/x').hasSource,
        isFalse,
      );
      expect(newsDetail('n1', sourceUrl: 'fonte.test/x').hasSource, isFalse);
    });

    test('isSaved acompanha interaction.isSaved', () {
      expect(newsDetail('n1', isSaved: true).isSaved, isTrue);
      expect(newsDetail('n1').isSaved, isFalse);
    });

    test('copyWith(isSaved:) troca só interaction.isSaved', () {
      final original = newsDetail('n1', content: 'Corpo');

      final saved = original.copyWith(isSaved: true);

      expect(saved.isSaved, isTrue);
      expect(saved.news.interaction.isRead, original.news.interaction.isRead);
      expect(saved.news.title, original.news.title);
      expect(saved.content, 'Corpo');
      expect(saved.likesCount, original.likesCount);
      expect(original.isSaved, isFalse);
      expect(original.copyWith().isSaved, isFalse);
    });
  });
}
