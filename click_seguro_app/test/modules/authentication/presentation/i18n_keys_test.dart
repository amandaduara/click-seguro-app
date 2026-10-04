import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// FR-018: toda chave `auth_*`/`home_placeholder_*` de `AppStrings` existe em
/// pt-BR e en-US, com texto não vazio.
void main() {
  final keyPattern = RegExp(r"'((?:auth|home_placeholder)_[a-z_]+)'");
  final declared = keyPattern
      .allMatches(File('lib/core/i18n/app_strings.dart').readAsStringSync())
      .map((m) => m.group(1)!)
      .toSet();

  test('AppStrings declara as chaves do módulo', () {
    expect(declared, isNotEmpty);
  });

  for (final locale in ['pt-BR', 'en-US']) {
    test('$locale tem todas as chaves com texto', () {
      final json =
          jsonDecode(
                File('assets/translations/$locale.json').readAsStringSync(),
              )
              as Map<String, dynamic>;

      for (final key in declared) {
        expect(json[key], isA<String>(), reason: '$locale sem $key');
        expect((json[key] as String).trim(), isNotEmpty, reason: key);
      }
    });
  }
}
