import 'dart:convert';

import 'package:click_seguro_app/modules/help/data/datasources/official_contacts_local_data_source.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lê contatos oficiais de asset bundle injetável', () async {
    final bundle = _TestAssetBundle(
      '[{"id":"police","name":"Polícia","phone":"190","type":"official"}]',
    );

    final contacts = await OfficialContactsLocalDataSource(
      bundle: bundle,
    ).read();

    expect(bundle.loadedPath, OfficialContactsLocalDataSource.assetPath);
    expect(contacts.single.toEntity().type, ContactType.official);
  });
}

class _TestAssetBundle extends CachingAssetBundle {
  _TestAssetBundle(this.json);

  final String json;
  String? loadedPath;

  @override
  Future<ByteData> load(String key) async {
    loadedPath = key;
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(json)));
  }
}
