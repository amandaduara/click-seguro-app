import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SharedPreferencesLocalCacheService> build([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    return SharedPreferencesLocalCacheService(
      await SharedPreferences.getInstance(),
    );
  }

  test('writeJson seguido de readJson devolve o mesmo Map', () async {
    final cache = await build();

    await cache.writeJson('feed', {'page': 1, 'ids': ['a', 'b']});

    expect(await cache.readJson('feed'), {
      'page': 1,
      'ids': ['a', 'b'],
    });
  });

  test('chave inexistente devolve null', () async {
    final cache = await build();

    expect(await cache.readJson('inexistente'), isNull);
  });

  test('valor que não é objeto JSON devolve null sem exceção', () async {
    final cache = await build({'quebrado': 'abc', 'lista': '[1, 2]'});

    expect(await cache.readJson('quebrado'), isNull);
    expect(await cache.readJson('lista'), isNull);
  });

  test('remove apaga a chave', () async {
    final cache = await build();
    await cache.writeJson('feed', {'page': 1});

    await cache.remove('feed');

    expect(await cache.readJson('feed'), isNull);
  });
}
