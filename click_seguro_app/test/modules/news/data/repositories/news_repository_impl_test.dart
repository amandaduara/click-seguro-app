import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/news/data/datasources/news_local_data_source.dart';
import 'package:click_seguro_app/modules/news/data/repositories/news_repository_impl.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_filter.dart';
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
}
