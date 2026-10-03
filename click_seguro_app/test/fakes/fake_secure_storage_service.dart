import 'package:click_seguro_app/modules/common/services/secure_storage_service.dart';

/// Armazenamento seguro em memória para testes, com falhas configuráveis.
class FakeSecureStorageService implements SecureStorageService {
  FakeSecureStorageService([Map<String, String>? initial])
      : values = {...?initial};

  final Map<String, String> values;

  /// Faz [read] lançar exceção (simula Keystore indisponível).
  bool failOnRead = false;

  /// Faz [write] e [delete] lançarem exceção.
  bool failOnWrite = false;

  int readCalls = 0;
  int writeCalls = 0;
  int deleteCalls = 0;

  @override
  Future<String?> read(String key) async {
    readCalls++;
    if (failOnRead) throw Exception('falha simulada de leitura');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    writeCalls++;
    if (failOnWrite) throw Exception('falha simulada de escrita');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    deleteCalls++;
    if (failOnWrite) throw Exception('falha simulada de escrita');
    values.remove(key);
  }
}
