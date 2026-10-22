import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:click_seguro_app/modules/help/data/models/contact_model.dart';

class OfficialContactsLocalDataSource {
  OfficialContactsLocalDataSource({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const String assetPath = 'assets/data/official_contacts.json';

  final AssetBundle _bundle;

  Future<List<ContactModel>> read() async {
    final decoded = jsonDecode(await _bundle.loadString(assetPath));
    if (decoded is! List) {
      throw const FormatException('Official contacts asset must be a list');
    }
    return [
      for (final value in decoded)
        if (value is Map<String, dynamic>) ContactModel.fromJson(value),
    ];
  }
}
