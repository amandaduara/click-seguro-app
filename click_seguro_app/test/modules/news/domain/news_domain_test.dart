import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_filter.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_categories_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_feed_page_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_feed_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_news_usecase.dart';
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
}
