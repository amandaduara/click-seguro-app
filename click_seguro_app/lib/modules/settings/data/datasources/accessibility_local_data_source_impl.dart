import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';
import 'package:click_seguro_app/modules/settings/data/datasources/accessibility_local_data_source.dart';

class AccessibilityLocalDataSourceImpl implements AccessibilityLocalDataSource {
  AccessibilityLocalDataSourceImpl(this._cache);

  static const String storageKey = 'accessibility_preferences_v1';

  final LocalCacheService _cache;

  @override
  Future<Map<String, dynamic>?> read() => _cache.readJson(storageKey);

  @override
  Future<void> write(Map<String, dynamic> json) =>
      _cache.writeJson(storageKey, json);
}
