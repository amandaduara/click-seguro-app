import 'dart:convert';

import 'package:click_seguro_app/modules/help/data/models/contact_model.dart';
import 'package:flutter/services.dart';

class OfficialContactsLocalDataSource {
  static const String assetPath = 'assets/data/official_contacts.json';

  Future<List<ContactModel>> read() async {
    final decoded = jsonDecode(await rootBundle.loadString(assetPath));
    if (decoded is! List) {
      throw const FormatException('Official contacts asset must be a list');
    }
    return [
      for (final value in decoded)
        if (value is Map<String, dynamic>) ContactModel.fromJson(value),
    ];
  }
}
