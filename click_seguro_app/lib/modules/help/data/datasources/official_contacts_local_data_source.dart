import 'dart:convert';

import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';
import 'package:click_seguro_app/modules/help/data/models/contact_model.dart';
import 'package:flutter/services.dart';

/// Cópia local dos contatos oficiais (última resposta da API) e o asset do
/// app, a semente offline para a primeira abertura sem internet.
class OfficialContactsLocalDataSource {
  OfficialContactsLocalDataSource(this._cache);

  static const String assetPath = 'assets/data/official_contacts.json';
  static const String cacheKey = 'help_official_contacts_v1';
  static const String _contactsField = 'contacts';

  final LocalCacheService _cache;

  /// Contatos do asset, no formato da API; item inválido é ignorado.
  Future<List<ContactModel>> readAsset() async {
    final decoded = jsonDecode(await rootBundle.loadString(assetPath));
    if (decoded is! List) {
      throw const FormatException('Official contacts asset must be a list');
    }
    return ContactModel.officialList(decoded);
  }

  /// A última lista guardada; vazia quando não há cópia.
  Future<List<ContactModel>> readCopy() async {
    final record = await _cache.readJson(cacheKey);
    final contacts = record?[_contactsField];
    return contacts is List ? ContactModel.officialList(contacts) : [];
  }

  Future<void> saveCopy(List<ContactModel> contacts) =>
      _cache.writeJson(cacheKey, {
        _contactsField: [for (final contact in contacts) contact.toJson()],
      });
}
