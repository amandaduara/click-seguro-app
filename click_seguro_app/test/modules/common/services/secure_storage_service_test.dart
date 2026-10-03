import 'package:click_seguro_app/modules/common/services/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FlutterSecureStorageService storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = FlutterSecureStorageService();
  });

  test('write seguido de read devolve o valor', () async {
    await storage.write('chave', 'valor');

    expect(await storage.read('chave'), 'valor');
  });

  test('read de chave inexistente devolve null', () async {
    expect(await storage.read('inexistente'), isNull);
  });

  test('delete remove só a chave pedida', () async {
    await storage.write('a', '1');
    await storage.write('b', '2');

    await storage.delete('a');

    expect(await storage.read('a'), isNull);
    expect(await storage.read('b'), '2');
  });
}
