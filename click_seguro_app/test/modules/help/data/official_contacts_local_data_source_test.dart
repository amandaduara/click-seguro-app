import 'dart:convert';

import 'package:click_seguro_app/modules/help/data/datasources/official_contacts_local_data_source.dart';
import 'package:click_seguro_app/modules/help/data/models/contact_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_local_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLocalCacheService cache;
  late OfficialContactsLocalDataSource dataSource;

  setUp(() {
    cache = FakeLocalCacheService();
    dataSource = OfficialContactsLocalDataSource(cache);
  });

  // O asset é a semente offline: os contatos com telefone que a API
  // devolvia em 2026-11-19, para a primeira abertura sem internet.
  test('o asset real tem contatos oficiais válidos para ligar', () async {
    final json =
        jsonDecode(
              await rootBundle.loadString(
                OfficialContactsLocalDataSource.assetPath,
              ),
            )
            as List<dynamic>;
    final contacts = await dataSource.readAsset();

    expect(contacts, isNotEmpty);
    expect(contacts, hasLength(json.length));
    expect(
      contacts.map((contact) => contact.id).toSet(),
      hasLength(json.length),
    );
    expect(contacts.first.name, 'Polícia Militar');
    expect(contacts.first.phone, '190');
    for (final contact in contacts) {
      expect(contact.name, isNotEmpty);
      expect(contact.phone, isNotEmpty);
      expect(contact.description, isNotEmpty);
      expect(contact.type.name, 'official');
    }
  });

  test('sem cópia guardada, readCopy devolve lista vazia', () async {
    expect(await dataSource.readCopy(), isEmpty);
  });

  test('saveCopy guarda na chave versionada e readCopy devolve', () async {
    final contacts = ContactModel.officialList([
      {'id': 'a', 'name': 'Polícia', 'phone': '190', 'description': 'Perigo'},
      {'id': 'b', 'name': 'INSS', 'phone': '135'},
    ]);

    await dataSource.saveCopy(contacts);
    final copy = await dataSource.readCopy();

    expect(cache.values.keys, [OfficialContactsLocalDataSource.cacheKey]);
    expect(OfficialContactsLocalDataSource.cacheKey, endsWith('_v1'));
    expect(copy.map((contact) => contact.id), ['a', 'b']);
    expect(copy.first.description, 'Perigo');
  });

  test('cópia corrompida: itens inválidos ignorados', () async {
    cache.values[OfficialContactsLocalDataSource.cacheKey] = {
      'contacts': [
        {'id': 'a', 'name': 'Polícia', 'phone': '190'},
        {'id': 'b'},
      ],
    };

    expect((await dataSource.readCopy()).map((c) => c.id), ['a']);

    cache.values[OfficialContactsLocalDataSource.cacheKey] = {
      'contacts': 'nada',
    };
    expect(await dataSource.readCopy(), isEmpty);
  });
}
