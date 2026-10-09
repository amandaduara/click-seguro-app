import 'dart:async';

import 'package:click_seguro_app/core/errors/cache_failure.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_accessibility_preferences_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/save_accessibility_preferences_usecase.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/accessibility_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_accessibility_repository.dart';

void main() {
  const defaults = AccessibilityPreferences.defaults();

  late FakeAccessibilityRepository repository;
  late AccessibilityPreferencesNotifier notifier;
  late AccessibilityController controller;
  late int notifications;

  setUp(() {
    repository = FakeAccessibilityRepository();
    notifier = AccessibilityPreferencesNotifier();
    controller = AccessibilityController(
      getPreferences: GetAccessibilityPreferencesUseCase(repository),
      savePreferences: SaveAccessibilityPreferencesUseCase(repository),
      notifier: notifier,
    );
    notifications = 0;
    controller.addListener(() => notifications++);
  });

  group('load', () {
    test('publica o que estava salvo (RF-041)', () async {
      final stored = defaults.copyWith(
        fontScale: FontScaleLevel.largest,
        highContrast: true,
      );
      repository.stored = stored;

      await controller.load();

      expect(controller.preferences, stored);
      expect(notifier.value, stored);
      expect(notifications, 1);
      expect(repository.saved, isEmpty);
    });

    test('sem nada salvo → padrões', () async {
      await controller.load();

      expect(notifier.value, defaults);
    });
  });

  group('mudanças', () {
    test('cada set muda o notifier na hora e grava (FR-006, FR-007)', () async {
      await controller.setFontScale(FontScaleLevel.larger);
      await controller.setHighContrast(true);
      await controller.setAutoReadAloud(true);
      await controller.setReadingSpeed(ReadingSpeed.slow);

      const expected = AccessibilityPreferences(
        fontScale: FontScaleLevel.larger,
        highContrast: true,
        autoReadAloud: true,
        readingSpeed: ReadingSpeed.slow,
      );
      expect(notifier.value, expected);
      expect(controller.preferences, expected);
      expect(repository.stored, expected);
      expect(repository.saved, hasLength(4));
      expect(notifications, 4);
    });

    test('o valor muda antes de a gravação terminar', () async {
      repository.saveGate = Completer<void>();

      final Future<void> saving = controller.setHighContrast(true);

      expect(notifier.value.highContrast, isTrue);
      repository.saveGate!.complete();
      await saving;
    });

    test('mesmo valor não grava nem avisa', () async {
      await controller.setFontScale(FontScaleLevel.standard);

      expect(repository.saved, isEmpty);
      expect(notifications, 0);
    });

    test('falha ao gravar mantém o valor até fechar o app (FR-009)', () async {
      repository.saveFailure = const CacheFailure();

      await controller.setHighContrast(true);

      expect(notifier.value.highContrast, isTrue);
      expect(repository.stored, defaults);
    });

    test('mudanças seguidas: gravadas em ordem, a última vence', () async {
      repository.saveGate = Completer<void>();

      final first = controller.setFontScale(FontScaleLevel.large);
      final second = controller.setFontScale(FontScaleLevel.largest);
      repository.saveGate!.complete();
      await Future.wait([first, second]);

      expect(repository.saved.map((p) => p.fontScale), [
        FontScaleLevel.large,
        FontScaleLevel.largest,
      ]);
      expect(repository.stored.fontScale, FontScaleLevel.largest);
      expect(notifier.value.fontScale, FontScaleLevel.largest);
    });
  });
}
