import 'dart:convert';

import 'package:click_seguro_app/modules/help/data/datasources/official_contacts_local_data_source.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mapeia o asset oficial real e valida contatos configurados', () async {
    final json = jsonDecode(
      await rootBundle.loadString(OfficialContactsLocalDataSource.assetPath),
    ) as List<dynamic>;
    final contacts = await OfficialContactsLocalDataSource().read();

    expect(contacts, hasLength(json.length));
    expect(contacts.map((contact) => contact.id).toSet(), hasLength(json.length));
    for (final contact in contacts) {
      expect(contact.id, isNotEmpty);
      expect(contact.name, isNotEmpty);
      expect(contact.phone, isNotEmpty);
      expect(contact.type.name, 'official');
    }
  });
}
