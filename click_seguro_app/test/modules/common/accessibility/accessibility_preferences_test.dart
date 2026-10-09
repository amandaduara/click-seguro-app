import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FontScaleLevel', () {
    test('quatro níveis: padrão e três maiores (FR-002)', () {
      expect(FontScaleLevel.values.map((level) => level.factor), [
        1.0,
        1.15,
        1.3,
        1.5,
      ]);
    });

    test('teto da escala total é 2× (FR-004)', () {
      expect(FontScaleLevel.maxTotalScale, 2.0);
    });

    test('escala total multiplica a do sistema e respeita o teto', () {
      expect(FontScaleLevel.larger.totalScale(1.0), 1.3);
      expect(FontScaleLevel.large.totalScale(1.2), closeTo(1.38, 0.0001));
      expect(FontScaleLevel.largest.totalScale(1.5), 2.0);
      expect(FontScaleLevel.standard.totalScale(0.85), 0.85);
    });
  });

  group('AccessibilityPreferences', () {
    test('padrões: fonte padrão, contraste normal, sem leitura automática, '
        'velocidade normal (FR-008)', () {
      const preferences = AccessibilityPreferences.defaults();

      expect(preferences.fontScale, FontScaleLevel.standard);
      expect(preferences.highContrast, isFalse);
      expect(preferences.autoReadAloud, isFalse);
      expect(preferences.readingSpeed, ReadingSpeed.normal);
    });

    test('copyWith troca só o campo pedido', () {
      const preferences = AccessibilityPreferences.defaults();

      final changed = preferences.copyWith(highContrast: true);

      expect(changed.highContrast, isTrue);
      expect(changed.fontScale, preferences.fontScale);
      expect(changed.autoReadAloud, preferences.autoReadAloud);
      expect(changed.readingSpeed, preferences.readingSpeed);
    });

    test('igualdade por valor', () {
      const a = AccessibilityPreferences(
        fontScale: FontScaleLevel.large,
        highContrast: true,
        autoReadAloud: true,
        readingSpeed: ReadingSpeed.slow,
      );
      final b = const AccessibilityPreferences.defaults().copyWith(
        fontScale: FontScaleLevel.large,
        highContrast: true,
        autoReadAloud: true,
        readingSpeed: ReadingSpeed.slow,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const AccessibilityPreferences.defaults()));
    });
  });

  group('AccessibilityPreferencesNotifier', () {
    test('começa com os padrões e avisa ao mudar', () {
      final notifier = AccessibilityPreferencesNotifier();
      var notifications = 0;
      notifier.addListener(() => notifications++);

      expect(notifier.value, const AccessibilityPreferences.defaults());

      notifier.value = notifier.value.copyWith(autoReadAloud: true);

      expect(notifier.value.autoReadAloud, isTrue);
      expect(notifications, 1);
    });
  });
}
