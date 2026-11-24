import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Cache local não sensível (feed, contatos, preferências), guardado como JSON.
abstract class LocalCacheService {
  /// JSON guardado em [key], ou null se não existir ou não for um objeto JSON.
  Future<Map<String, dynamic>?> readJson(String key);

  Future<void> writeJson(String key, Map<String, dynamic> value);

  Future<void> remove(String key);
}

class SharedPreferencesLocalCacheService implements LocalCacheService {
  SharedPreferencesLocalCacheService(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<Map<String, dynamic>?> readJson(String key) async {
    final raw = _preferences.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    await _preferences.setString(key, jsonEncode(value));
  }

  @override
  Future<void> remove(String key) async {
    await _preferences.remove(key);
  }
}
