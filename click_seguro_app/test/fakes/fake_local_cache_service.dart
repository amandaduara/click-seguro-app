import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';

/// Cache local em memória para testes.
class FakeLocalCacheService implements LocalCacheService {
  final Map<String, Map<String, dynamic>> values = {};

  int writeCalls = 0;

  @override
  Future<Map<String, dynamic>?> readJson(String key) async => values[key];

  @override
  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    writeCalls++;
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}
