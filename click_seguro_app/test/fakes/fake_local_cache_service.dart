import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';

/// Cache local em memória para testes.
class FakeLocalCacheService implements LocalCacheService {
  final Map<String, Map<String, dynamic>> values = {};

  int writeCalls = 0;

  /// Simula o armazenamento do aparelho indisponível.
  bool throwOnRead = false;
  bool throwOnWrite = false;

  @override
  Future<Map<String, dynamic>?> readJson(String key) async {
    if (throwOnRead) throw StateError('armazenamento indisponível');
    return values[key];
  }

  @override
  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    writeCalls++;
    if (throwOnWrite) throw StateError('armazenamento indisponível');
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}
