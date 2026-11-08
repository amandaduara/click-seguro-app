import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:click_seguro_app/modules/settings/data/models/accessibility_preferences_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const custom = AccessibilityPreferences(
    fontScale: FontScaleLevel.larger,
    highContrast: true,
    autoReadAloud: true,
    readingSpeed: ReadingSpeed.slow,
    reduceMotion: true,
  );

  test('grava os nomes dos enums e os booleanos', () {
    expect(AccessibilityPreferencesModel.toJson(custom), {
      'fontScale': 'larger',
      'highContrast': true,
      'autoReadAloud': true,
      'readingSpeed': 'slow',
      'reduceMotion': true,
    });
  });

  test('ida e volta preserva tudo', () {
    final json = AccessibilityPreferencesModel.toJson(custom);

    expect(AccessibilityPreferencesModel.fromJson(json), custom);
  });

  test('registro vazio → padrões', () {
    expect(
      AccessibilityPreferencesModel.fromJson({}),
      const AccessibilityPreferences.defaults(),
    );
  });

  test('campo inválido cai no padrão só dele (FR-008)', () {
    final preferences = AccessibilityPreferencesModel.fromJson({
      'fontScale': 'gigante',
      'highContrast': 'sim',
      'autoReadAloud': true,
      'readingSpeed': 'slow',
    });

    expect(preferences.fontScale, FontScaleLevel.standard);
    expect(preferences.highContrast, isFalse);
    expect(preferences.autoReadAloud, isTrue);
    expect(preferences.readingSpeed, ReadingSpeed.slow);
  });

  test('registro antigo sem a velocidade mantém o resto', () {
    final preferences = AccessibilityPreferencesModel.fromJson({
      'fontScale': 'large',
      'highContrast': true,
    });

    expect(preferences.fontScale, FontScaleLevel.large);
    expect(preferences.highContrast, isTrue);
    expect(preferences.readingSpeed, ReadingSpeed.normal);
  });

  test('registro sem "Reduzir animações" (versão anterior) → desligado', () {
    final preferences = AccessibilityPreferencesModel.fromJson({
      'fontScale': 'large',
      'highContrast': true,
      'autoReadAloud': true,
      'readingSpeed': 'fast',
    });

    expect(preferences.reduceMotion, isFalse);
    expect(preferences.fontScale, FontScaleLevel.large);
  });

  test('"Reduzir animações" ilegível cai em desligado', () {
    expect(
      AccessibilityPreferencesModel.fromJson({
        'reduceMotion': 'sim',
      }).reduceMotion,
      isFalse,
    );
  });
}
