import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/news/data/datasources/news_local_data_source.dart';
import 'package:click_seguro_app/modules/news/data/repositories/news_repository_impl.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_filter.dart';
import 'package:click_seguro_app/modules/news/domain/failures/news_failures.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_news_data_sources.dart';
import '../../fakes/news_fixtures.dart';

void main() {
  late FakeNewsRemoteDataSource remote;
  late FakeNewsLocalDataSource local;
  late NewsRepositoryImpl repository;

  setUp(() {
    remote = FakeNewsRemoteDataSource();
    local = FakeNewsLocalDataSource();
    repository = NewsRepositoryImpl(remote, local);
  });

  CachedFeed cachedFeed() => CachedFeed(
    feedJson: feedJson(recent: [newsItemJson(id: 'guardada')]),
    reelsJson: reelsJson(),
    savedAt: DateTime.utc(2026, 10, 4),
  );

  group('getFeedFirstPage', () {
    test('ok: seções, Reels e grava a cópia', () async {
      remote.feed = feedJson(
        highlights: [newsItemJson(id: 'h1')],
        recommended: [newsItemJson(id: 'r1')],
        recent: newsItemsJson(2),
      );

      final feed = (await repository.getFeedFirstPage()).getOrElse(
        (_) => throw StateError('esperava Right'),
      );

      expect(feed.highlights.single.id, 'h1');
      expect(feed.recommended.single.id, 'r1');
      expect(feed.recent.items.map((n) => n.id), ['n1', 'n2']);
      expect(feed.reels.single.id, 'reel1');
      expect(feed.isFromCache, isFalse);
      expect(remote.feedPages, [1]);
      expect(local.writes, 1);
      expect(local.cached!.feedJson, remote.feed);
    });

    test('Reels falham sozinhos: feed sem Reels', () async {
      remote.reelsError = apiError(ApiErrorType.server);

      final feed = (await repository.getFeedFirstPage()).getOrElse(
        (_) => throw StateError('esperava Right'),
      );

      expect(feed.reels, isEmpty);
      expect(feed.recent.items, isNotEmpty);
      expect(local.cached!.reelsJson['data'], isEmpty);
    });

    for (final type in [
      ApiErrorType.connection,
      ApiErrorType.timeout,
      ApiErrorType.server,
    ]) {
      test('${type.name} com cópia: devolve a cópia', () async {
        remote.feedError = apiError(type);
        local.cached = cachedFeed();

        final feed = (await repository.getFeedFirstPage()).getOrElse(
          (_) => throw StateError('esperava Right'),
        );

        expect(feed.isFromCache, isTrue);
        expect(feed.recent.items.single.id, 'guardada');
      });
    }

    test('sem conexão e sem cópia: ConnectionFailure', () async {
      remote.feedError = apiError(ApiErrorType.connection);

      final result = await repository.getFeedFirstPage();

      expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
    });

    test('sessão recusada não usa a cópia', () async {
      remote.feedError = apiError(ApiErrorType.unauthorized);
      local.cached = cachedFeed();

      final result = await repository.getFeedFirstPage();

      expect(result.getLeft().toNullable(), isA<UnauthorizedFailure>());
    });
  });

  group('getFeedPage', () {
    test('página seguinte do feed', () async {
      remote.feed = feedJson(recent: newsItemsJson(1, start: 41));

      final page = (await repository.getFeedPage(
        3,
      )).getOrElse((_) => throw StateError('esperava Right'));

      expect(remote.feedPages, [3]);
      expect(page.page, 3);
      expect(page.items.single.id, 'n41');
      expect(local.writes, 0);
    });

    test('erro vira Failure', () async {
      remote.feedError = apiError(ApiErrorType.connection);

      final result = await repository.getFeedPage(2);

      expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
    });
  });

  group('getNews', () {
    test('repassa categoria, busca e página', () async {
      await repository.getNews(
        const NewsFilter(categorySlug: 'phishing', search: ' pix '),
        2,
      );

      expect(remote.listCalls.single, (
        page: 2,
        category: 'phishing',
        search: 'pix',
      ));
    });

    test('busca com menos de 2 caracteres não vai ao servidor', () async {
      await repository.getNews(const NewsFilter(search: 'p'), 1);

      expect(remote.listCalls.single.search, isNull);
    });

    test('erro vira Failure', () async {
      remote.listError = apiError(ApiErrorType.server);

      final result = await repository.getNews(const NewsFilter(), 1);

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });
  });

  group('getCategories', () {
    test('ok: só as ativas', () async {
      final categories = (await repository.getCategories()).getOrElse(
        (_) => throw StateError('esperava Right'),
      );

      expect(categories.map((c) => c.slug), ['phishing', 'golpes-bancarios']);
    });

    test('erro vira Failure', () async {
      remote.categoriesError = apiError(ApiErrorType.connection);

      final result = await repository.getCategories();

      expect(result.isLeft(), isTrue);
    });
  });

  group('Reels (specs/008)', () {
    test('getReels devolve a parte com o cursor', () async {
      remote.reelsPages[null] = reelsJson(
        items: [reelItemJson(id: 'r1')],
        nextCursor: 'c2',
      );

      final page = (await repository.getReels()).getOrElse(
        (_) => throw StateError('esperava Right'),
      );

      expect(page.items.single.id, 'r1');
      expect(page.nextCursor, 'c2');
      expect(remote.reelsCursors, [null]);
    });

    test('getReels repassa o cursor', () async {
      remote.reelsPages['c2'] = reelsJson(items: [reelItemJson(id: 'r9')]);

      final page = (await repository.getReels(
        cursor: 'c2',
      )).getOrElse((_) => throw StateError('esperava Right'));

      expect(page.items.single.id, 'r9');
      expect(remote.reelsCursors, ['c2']);
    });

    test('getReels sem conexão vira ConnectionFailure', () async {
      remote.reelsError = apiError(ApiErrorType.connection);

      final result = await repository.getReels();

      expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
    });

    test('toggleLike e toggleSave devolvem o estado do servidor', () async {
      remote.likeResult = likeJson(liked: true, likesCount: 8);
      remote.saveResult = false;

      final like = (await repository.toggleLike(
        'n1',
      )).getOrElse((_) => throw StateError('esperava Right'));
      final saved = (await repository.toggleSave(
        'n1',
      )).getOrElse((_) => throw StateError('esperava Right'));

      expect(like.liked, isTrue);
      expect(like.likesCount, 8);
      expect(saved, isFalse);
      expect(remote.likeCalls, ['n1']);
      expect(remote.saveCalls, ['n1']);
    });

    test('404 ou NEWS_NOT_FOUND vira NewsNotFoundFailure', () async {
      remote.likeError = ApiException(
        type: ApiErrorType.client,
        message: 'x',
        statusCode: 404,
      );
      remote.saveError = ApiException(
        type: ApiErrorType.client,
        message: 'x',
        errorCode: 'NEWS_NOT_FOUND',
      );

      final like = await repository.toggleLike('n1');
      final save = await repository.toggleSave('n1');

      expect(like.getLeft().toNullable(), isA<NewsNotFoundFailure>());
      expect(save.getLeft().toNullable(), isA<NewsNotFoundFailure>());
    });

    test('401 e 500 seguem o mapeamento padrão', () async {
      remote.likeError = apiError(ApiErrorType.unauthorized);
      remote.saveError = apiError(ApiErrorType.server);

      final like = await repository.toggleLike('n1');
      final save = await repository.toggleSave('n1');

      expect(like.getLeft().toNullable(), isA<UnauthorizedFailure>());
      expect(save.getLeft().toNullable(), isA<ServerFailure>());
    });
  });

  group('getNewsDetail (specs/010)', () {
    test('ok: resultado do servidor e grava a cópia', () async {
      remote.detail = newsDetailJson(
        id: 'n1',
        content: 'Texto do servidor',
        suggestedModule: suggestedModuleJson(),
      );

      final result = (await repository.getNewsDetail(
        'n1',
      )).getOrElse((_) => throw StateError('esperava Right'));

      expect(result.isFromCache, isFalse);
      expect(result.detail.content, 'Texto do servidor');
      expect(result.detail.suggestedModule!.id, 'm1');
      expect(remote.detailCalls, ['n1']);
      expect(local.detailWrites, 1);
      expect(local.details['n1'], remote.detail);
    });

    test(
      'grava a cópia também com isSaved == false e para visitante',
      () async {
        remote.detail = newsDetailJson(id: 'n1', isSaved: false);

        await repository.getNewsDetail('n1');

        expect(local.details.keys, ['n1']);
      },
    );

    for (final type in [ApiErrorType.connection, ApiErrorType.timeout]) {
      test('${type.name} com cópia: devolve a cópia', () async {
        remote.detailError = apiError(type);
        local.details['n1'] = newsDetailJson(id: 'n1', content: 'Guardado');

        final result = (await repository.getNewsDetail(
          'n1',
        )).getOrElse((_) => throw StateError('esperava Right'));

        expect(result.isFromCache, isTrue);
        expect(result.detail.content, 'Guardado');
        expect(local.detailWrites, 0);
      });
    }

    test('sem conexão e sem cópia: ConnectionFailure', () async {
      remote.detailError = apiError(ApiErrorType.connection);

      final result = await repository.getNewsDetail('n1');

      expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
    });

    test('erro server (500) não usa a cópia', () async {
      remote.detailError = apiError(ApiErrorType.server);
      local.details['n1'] = newsDetailJson(id: 'n1');

      final result = await repository.getNewsDetail('n1');

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });

    test(
      '404 NEWS_NOT_FOUND: NewsNotFoundFailure sem tocar na cópia',
      () async {
        remote.detailError = ApiException(
          type: ApiErrorType.client,
          message: 'x',
          statusCode: 404,
          errorCode: 'NEWS_NOT_FOUND',
        );
        local.details['n1'] = newsDetailJson(id: 'n1');

        final result = await repository.getNewsDetail('n1');

        expect(result.getLeft().toNullable(), isA<NewsNotFoundFailure>());
        expect(local.details['n1'], isNotNull);
        expect(local.detailWrites, 0);
      },
    );

    test(
      'resposta malformada: falha genérica, sem lançar nem gravar',
      () async {
        remote.detail = newsDetailJson(id: 'n1')..remove('title');

        final result = await repository.getNewsDetail('n1');

        expect(result.getLeft().toNullable(), isA<ServerFailure>());
        expect(local.detailWrites, 0);
      },
    );
  });

  group('markAsRead (specs/010)', () {
    test('sucesso: Right(unit)', () async {
      final result = await repository.markAsRead('n1');

      expect(result.isRight(), isTrue);
      expect(remote.readCalls, ['n1']);
    });

    test('falha: Left', () async {
      remote.markAsReadError = apiError(ApiErrorType.connection);

      final result = await repository.markAsRead('n1');

      expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
    });
  });

  group('getSavedNews (specs/010)', () {
    test('página 1: resultado do servidor e grava a cópia', () async {
      remote.savedPages[1] = savedListJson(
        items: [newsItemJson(id: 's1', isSaved: true)],
        hasNextPage: true,
      );

      final result = (await repository.getSavedNews(
        1,
      )).getOrElse((_) => throw StateError('esperava Right'));

      expect(result.isFromCache, isFalse);
      expect(result.page.items.single.id, 's1');
      expect(result.page.hasMore, isTrue);
      expect(result.page.page, 1);
      expect(remote.savedCalls, [1]);
      expect(local.savedWrites, 1);
      expect(local.savedPage, remote.savedPages[1]);
    });

    test('só a página 1 grava a cópia', () async {
      remote.savedPages[2] = savedListJson(
        items: [newsItemJson(id: 's21', isSaved: true)],
        page: 2,
      );

      final result = (await repository.getSavedNews(
        2,
      )).getOrElse((_) => throw StateError('esperava Right'));

      expect(result.page.page, 2);
      expect(local.savedWrites, 0);
    });

    for (final type in [ApiErrorType.connection, ApiErrorType.timeout]) {
      test('${type.name} na página 1 com cópia: isFromCache', () async {
        remote.savedError = apiError(type);
        local.savedPage = savedListJson(
          items: [newsItemJson(id: 'guardada', isSaved: true)],
        );

        final result = (await repository.getSavedNews(
          1,
        )).getOrElse((_) => throw StateError('esperava Right'));

        expect(result.isFromCache, isTrue);
        expect(result.page.items.single.id, 'guardada');
      });
    }

    test('página 1 sem conexão e sem cópia: Left', () async {
      remote.savedError = apiError(ApiErrorType.connection);

      final result = await repository.getSavedNews(1);

      expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
    });

    test('página 2 sem internet: Left, sem cópia', () async {
      remote.savedError = apiError(ApiErrorType.connection);
      local.savedPage = savedListJson(items: newsItemsJson(1));

      final result = await repository.getSavedNews(2);

      expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
    });

    test('erro server não usa a cópia', () async {
      remote.savedError = apiError(ApiErrorType.server);
      local.savedPage = savedListJson(items: newsItemsJson(1));

      final result = await repository.getSavedNews(1);

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });

    test('401 vira UnauthorizedFailure', () async {
      remote.savedError = apiError(ApiErrorType.unauthorized);

      final result = await repository.getSavedNews(1);

      expect(result.getLeft().toNullable(), isA<UnauthorizedFailure>());
    });
  });
}
