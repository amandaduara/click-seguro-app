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
}
