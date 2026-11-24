import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';
import 'package:click_seguro_app/modules/news/data/datasources/news_local_data_source.dart';

class NewsLocalDataSourceImpl implements NewsLocalDataSource {
  /// [owner] devolve o dono atual das cópias de conta (e-mail da sessão);
  /// sem ele, `guest` (specs/010, R3).
  NewsLocalDataSourceImpl(
    this._cache, {
    DateTime Function()? now,
    String Function()? owner,
  }) : _now = now ?? DateTime.now,
       _owner = owner ?? _guestOwner;

  static const String feedCacheKey = 'news_feed_cache_v1';
  static const String detailCacheKey = 'news_detail_cache_v1';
  static const String savedCacheKey = 'news_saved_cache_v1';

  /// Notícias abertas guardadas para uso sem internet.
  static const int maxCachedDetails = 30;

  static String _guestOwner() => 'guest';

  final LocalCacheService _cache;
  final DateTime Function() _now;
  final String Function() _owner;

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

  @override
  Future<Map<String, dynamic>?> readDetail(String id) async {
    for (final item in await _readDetailItems()) {
      if (_isDetailOf(item, id)) return item['json'] as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<void> writeDetail(Map<String, dynamic> json) async {
    final items = await _readDetailItems();
    final updated = [
      {'savedAt': _now().toIso8601String(), 'json': json},
      for (final item in items)
        if (!_isDetailOf(item, json['id'])) item,
    ];
    await _cache.writeJson(detailCacheKey, {
      'owner': _owner(),
      'items': updated.take(maxCachedDetails).toList(),
    });
  }

  @override
  Future<Map<String, dynamic>?> readSavedPage() async {
    final record = await _cache.readJson(savedCacheKey);
    final page = record?['page'];
    if (record?['owner'] != _owner() || page is! Map<String, dynamic>) {
      return null;
    }
    return page;
  }

  @override
  Future<void> writeSavedPage(Map<String, dynamic> json) => _cache.writeJson(
    savedCacheKey,
    {'owner': _owner(), 'savedAt': _now().toIso8601String(), 'page': json},
  );

  @override
  Future<void> clearAccountCopies() async {
    await _cache.remove(detailCacheKey);
    await _cache.remove(savedCacheKey);
  }

  bool _isDetailOf(Map<String, dynamic> item, Object? id) {
    final json = item['json'];
    return json is Map<String, dynamic> && json['id'] == id;
  }

  /// Itens bem formados da cópia de detalhes; vazio se for de outra conta ou
  /// estiver ilegível.
  Future<List<Map<String, dynamic>>> _readDetailItems() async {
    final record = await _cache.readJson(detailCacheKey);
    final items = record?['items'];
    if (record?['owner'] != _owner() || items is! List) return const [];
    return [
      for (final item in items)
        if (item is Map<String, dynamic>) item,
    ];
  }
}
