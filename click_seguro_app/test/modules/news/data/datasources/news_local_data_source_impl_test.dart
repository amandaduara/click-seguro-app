import 'package:click_seguro_app/modules/news/data/datasources/news_local_data_source_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_local_cache_service.dart';
import '../../fakes/news_fixtures.dart';

void main() {
  late FakeLocalCacheService cache;
  late NewsLocalDataSourceImpl dataSource;
  final savedAt = DateTime.utc(2026, 10, 5, 12);

  setUp(() {
    cache = FakeLocalCacheService();
    dataSource = NewsLocalDataSourceImpl(cache, now: () => savedAt);
  });

  test('grava e lê o feed, os Reels e o momento', () async {
    final feed = feedJson(recent: newsItemsJson(2));
    final reels = reelsJson(items: [reelItemJson(id: 'r1')]);

    await dataSource.writeFeed(feed, reels);
    final cached = await dataSource.readFeed();

    expect(cache.values.keys, [NewsLocalDataSourceImpl.feedCacheKey]);
    expect(cached!.feedJson, feed);
    expect(cached.reelsJson, reels);
    expect(cached.savedAt, savedAt);
  });

  test('nada guardado → null', () async {
    expect(await dataSource.readFeed(), isNull);
  });

  test('registro sem feed → null', () async {
    cache.values[NewsLocalDataSourceImpl.feedCacheKey] = {
      'savedAt': savedAt.toIso8601String(),
    };

    expect(await dataSource.readFeed(), isNull);
  });

  test('data ilegível → null', () async {
    cache.values[NewsLocalDataSourceImpl.feedCacheKey] = {
      'savedAt': 'ontem',
      'feed': feedJson(),
      'reels': reelsJson(),
    };

    expect(await dataSource.readFeed(), isNull);
  });

  group('detalhes (specs/010)', () {
    late String owner;
    late DateTime clock;
    late NewsLocalDataSourceImpl copies;

    List<dynamic> storedItems() =>
        cache.values[NewsLocalDataSourceImpl.detailCacheKey]!['items']
            as List<dynamic>;

    setUp(() {
      owner = 'pessoa@exemplo.com';
      clock = DateTime.utc(2026, 10, 9, 3);
      copies = NewsLocalDataSourceImpl(
        cache,
        now: () => clock,
        owner: () => owner,
      );
    });

    test('writeDetail grava com o dono e o momento', () async {
      await copies.writeDetail(newsDetailJson(id: 'n1'));

      final record = cache.values[NewsLocalDataSourceImpl.detailCacheKey]!;
      expect(NewsLocalDataSourceImpl.detailCacheKey, 'news_detail_cache_v1');
      expect(record['owner'], 'pessoa@exemplo.com');
      final item = (record['items'] as List).single as Map<String, dynamic>;
      expect(item['savedAt'], clock.toIso8601String());
      expect((item['json'] as Map)['id'], 'n1');
    });

    test('readDetail devolve o JSON cru; id ausente → null', () async {
      final json = newsDetailJson(id: 'n1', content: 'Texto guardado');
      await copies.writeDetail(json);

      expect(await copies.readDetail('n1'), json);
      expect(await copies.readDetail('n2'), isNull);
    });

    test('mais recente primeiro; id existente sobe sem repetir', () async {
      await copies.writeDetail(newsDetailJson(id: 'a'));
      await copies.writeDetail(newsDetailJson(id: 'b'));
      await copies.writeDetail(newsDetailJson(id: 'c'));
      await copies.writeDetail(newsDetailJson(id: 'a', content: 'novo'));

      final ids = [
        for (final item in storedItems()) ((item as Map)['json'] as Map)['id'],
      ];
      expect(ids, ['a', 'c', 'b']);
      expect((await copies.readDetail('a'))!['content'], 'novo');
    });

    test('guarda no máximo 30; o excedente sai do fim', () async {
      expect(NewsLocalDataSourceImpl.maxCachedDetails, 30);
      for (var i = 1; i <= 32; i++) {
        await copies.writeDetail(newsDetailJson(id: 'n$i'));
      }

      expect(storedItems(), hasLength(30));
      expect(await copies.readDetail('n32'), isNotNull);
      expect(await copies.readDetail('n3'), isNotNull);
      expect(await copies.readDetail('n2'), isNull);
      expect(await copies.readDetail('n1'), isNull);
    });

    test(
      'cópia de outro dono → null, substituída na próxima gravação',
      () async {
        await copies.writeDetail(newsDetailJson(id: 'n1'));
        owner = 'outra@exemplo.com';

        expect(await copies.readDetail('n1'), isNull);

        await copies.writeDetail(newsDetailJson(id: 'n2'));

        final record = cache.values[NewsLocalDataSourceImpl.detailCacheKey]!;
        expect(record['owner'], 'outra@exemplo.com');
        expect(storedItems(), hasLength(1));
        expect(await copies.readDetail('n2'), isNotNull);
      },
    );

    test('visitante (dono padrão) grava com owner guest', () async {
      await dataSource.writeDetail(newsDetailJson(id: 'n1'));

      expect(
        cache.values[NewsLocalDataSourceImpl.detailCacheKey]!['owner'],
        'guest',
      );
      expect(await dataSource.readDetail('n1'), isNotNull);
    });

    test('JSON ilegível → null', () async {
      cache.values[NewsLocalDataSourceImpl.detailCacheKey] = {
        'owner': 'pessoa@exemplo.com',
        'items': 'não é uma lista',
      };

      expect(await copies.readDetail('n1'), isNull);

      cache.values[NewsLocalDataSourceImpl.detailCacheKey] = {
        'owner': 'pessoa@exemplo.com',
        'items': [
          {'savedAt': 'x', 'json': 'não é um objeto'},
          42,
        ],
      };

      expect(await copies.readDetail('n1'), isNull);
    });
  });

  group('salvas (specs/010)', () {
    late String owner;
    late NewsLocalDataSourceImpl copies;

    setUp(() {
      owner = 'pessoa@exemplo.com';
      copies = NewsLocalDataSourceImpl(
        cache,
        now: () => savedAt,
        owner: () => owner,
      );
    });

    test('writeSavedPage/readSavedPage: só a página 1, substituída', () async {
      final first = savedListJson(
        items: [newsItemJson(id: 'n1', isSaved: true)],
      );
      final second = savedListJson(
        items: [newsItemJson(id: 'n2', isSaved: true)],
      );

      await copies.writeSavedPage(first);
      expect(await copies.readSavedPage(), first);

      await copies.writeSavedPage(second);

      expect(await copies.readSavedPage(), second);
      expect(NewsLocalDataSourceImpl.savedCacheKey, 'news_saved_cache_v1');
      final record = cache.values[NewsLocalDataSourceImpl.savedCacheKey]!;
      expect(record['owner'], 'pessoa@exemplo.com');
      expect(record['savedAt'], savedAt.toIso8601String());
    });

    test('nada guardado ou dono diferente → null', () async {
      expect(await copies.readSavedPage(), isNull);

      await copies.writeSavedPage(savedListJson(items: const []));
      owner = 'outra@exemplo.com';

      expect(await copies.readSavedPage(), isNull);
    });

    test('registro ilegível → null', () async {
      cache.values[NewsLocalDataSourceImpl.savedCacheKey] = {
        'owner': 'pessoa@exemplo.com',
        'page': 'não é um objeto',
      };

      expect(await copies.readSavedPage(), isNull);
    });
  });

  test('clearAccountCopies remove detalhes e salvas, não o feed', () async {
    await dataSource.writeFeed(feedJson(), reelsJson());
    await dataSource.writeDetail(newsDetailJson(id: 'n1'));
    await dataSource.writeSavedPage(savedListJson(items: const []));

    await dataSource.clearAccountCopies();

    expect(cache.values.keys, [NewsLocalDataSourceImpl.feedCacheKey]);
  });
}
