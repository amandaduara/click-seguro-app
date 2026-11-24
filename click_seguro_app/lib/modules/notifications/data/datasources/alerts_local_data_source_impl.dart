import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';
import 'package:click_seguro_app/modules/notifications/data/datasources/alerts_local_data_source.dart';
import 'package:click_seguro_app/modules/notifications/data/models/alerts_snapshot_model.dart';

class AlertsLocalDataSourceImpl implements AlertsLocalDataSource {
  /// [owner] devolve o dono atual do registro (e-mail da sessão); sem ele,
  /// `guest` (R4 de specs/011-alertas-locais).
  AlertsLocalDataSourceImpl(this._cache, {String Function()? owner})
    : _owner = owner ?? _guestOwner;

  static const String cacheKey = 'notifications_alerts_v1';

  static String _guestOwner() => 'guest';

  final LocalCacheService _cache;
  final String Function() _owner;

  @override
  Future<AlertsSnapshotModel?> read() async {
    final record = await _cache.readJson(cacheKey);
    if (record == null || record['owner'] != _owner()) return null;
    return AlertsSnapshotModel.fromJson(record);
  }

  @override
  Future<void> write(AlertsSnapshotModel snapshot) =>
      _cache.writeJson(cacheKey, {'owner': _owner(), ...snapshot.toJson()});

  @override
  Future<void> clear() => _cache.remove(cacheKey);
}
