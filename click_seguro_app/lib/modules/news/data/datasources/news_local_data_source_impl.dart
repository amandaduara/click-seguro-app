import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';
import 'package:click_seguro_app/modules/news/data/datasources/news_local_data_source.dart';

class NewsLocalDataSourceImpl implements NewsLocalDataSource {
  NewsLocalDataSourceImpl(this._cache, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const String feedCacheKey = 'news_feed_cache_v1';

  final LocalCacheService _cache;
  final DateTime Function() _now;

  @override
  Future<CachedFeed?> readFeed() async {
    final record = await _cache.readJson(feedCacheKey);
    final feed = record?['feed'];
    final reels = record?['reels'];
    final savedAt = DateTime.tryParse(record?['savedAt'] as String? ?? '');
    if (feed is! Map<String, dynamic> || savedAt == null) return null;
    return CachedFeed(
      feedJson: feed,
      reelsJson: reels is Map<String, dynamic> ? reels : const {'data': []},
      savedAt: savedAt,
    );
  }

  @override
  Future<void> writeFeed(
    Map<String, dynamic> feedJson,
    Map<String, dynamic> reelsJson,
  ) => _cache.writeJson(feedCacheKey, {
    'savedAt': _now().toIso8601String(),
    'feed': feedJson,
    'reels': reelsJson,
  });
}
