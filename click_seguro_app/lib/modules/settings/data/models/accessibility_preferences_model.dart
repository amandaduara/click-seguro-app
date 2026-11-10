import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';

/// Registro salvo das preferências. Lido campo a campo: valor ausente ou
/// ilegível cai no padrão só daquele campo (FR-008).
abstract final class AccessibilityPreferencesModel {
  static const String fontScaleKey = 'fontScale';
  static const String highContrastKey = 'highContrast';
  static const String autoReadAloudKey = 'autoReadAloud';
  static const String readingSpeedKey = 'readingSpeed';
  static const String reduceMotionKey = 'reduceMotion';

  static AccessibilityPreferences fromJson(Map<String, dynamic> json) {
    const defaults = AccessibilityPreferences.defaults();
    return AccessibilityPreferences(
      fontScale: _enumByName(
        FontScaleLevel.values,
        json[fontScaleKey],
        defaults.fontScale,
      ),
      highContrast: _bool(json[highContrastKey], defaults.highContrast),
      autoReadAloud: _bool(json[autoReadAloudKey], defaults.autoReadAloud),
      readingSpeed: _enumByName(
        ReadingSpeed.values,
        json[readingSpeedKey],
        defaults.readingSpeed,
      ),
      // Ausente no que foi guardado antes da specs/022: lido como desligado.
      reduceMotion: _bool(json[reduceMotionKey], defaults.reduceMotion),
    );
  }

  static Map<String, dynamic> toJson(AccessibilityPreferences preferences) => {
    fontScaleKey: preferences.fontScale.name,
    highContrastKey: preferences.highContrast,
    autoReadAloudKey: preferences.autoReadAloud,
    readingSpeedKey: preferences.readingSpeed.name,
    reduceMotionKey: preferences.reduceMotion,
  };

  static bool _bool(Object? value, bool fallback) =>
      value is bool ? value : fallback;

  static T _enumByName<T extends Enum>(
    List<T> values,
    Object? name,
    T fallback,
  ) {
    for (final T value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
