import 'dart:async';
import 'dart:ui' show Locale;

import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_text_to_speech_service.dart';

void main() {
  const portuguese = Locale('pt', 'BR');
  const english = Locale('en', 'US');

  late FakeTextToSpeechService tts;
  late ReadAloudController controller;
  late int notifications;

  setUp(() {
    tts = FakeTextToSpeechService(availableLanguages: {SpeechLanguage.ptBr});
    controller = ReadAloudController(tts);
    notifications = 0;
    controller.addListener(() => notifications++);
  });

  test('começa indisponível, parado e na velocidade normal', () {
    expect(controller.isAvailable, isFalse);
    expect(controller.isSpeaking, isFalse);
    expect(controller.speed, ReadingSpeed.normal);
  });

  test('1. com voz no idioma do app → disponível', () async {
    await controller.prepare(portuguese);

    expect(controller.isAvailable, isTrue);
    expect(notifications, 1);
  });

  test('2. sem voz no idioma do app → indisponível, sem erro', () async {
    tts.availableLanguages = {};

    await controller.prepare(portuguese);

    expect(controller.isAvailable, isFalse);
  });

  test(
    '3. ouvir lê no idioma e na velocidade atuais e marca "lendo"',
    () async {
      await controller.prepare(portuguese);

      final reading = controller.speak('texto');

      expect(controller.isSpeaking, isTrue);
      expect(tts.spoken.single, (
        text: 'texto',
        language: SpeechLanguage.ptBr,
        speed: ReadingSpeed.normal,
      ));

      tts.finishSpeaking();
      await reading;
    },
  );

  test('4. parar volta a "parado" na hora', () async {
    await controller.prepare(portuguese);
    final reading = controller.speak('texto');

    await controller.stop();

    expect(controller.isSpeaking, isFalse);
    expect(tts.stopCalls, 1);
    await reading;
    expect(controller.isSpeaking, isFalse);
  });

  test('5. ao terminar, volta a "parado" sozinho', () async {
    await controller.prepare(portuguese);
    final reading = controller.speak('texto');

    tts.finishSpeaking();
    await reading;

    expect(controller.isSpeaking, isFalse);
  });

  test(
    '6. uma leitura nova interrompe a anterior, sem marcar "parado"',
    () async {
      await controller.prepare(portuguese);
      final first = controller.speak('A');

      final second = controller.speak('B');
      await first;

      expect(tts.spoken.map((s) => s.text), ['A', 'B']);
      expect(controller.isSpeaking, isTrue);

      tts.finishSpeaking();
      await second;
      expect(controller.isSpeaking, isFalse);
    },
  );

  test('7. mudar a velocidade vale para a próxima leitura', () async {
    await controller.prepare(portuguese);
    final first = controller.speak('A');

    controller.setSpeed(ReadingSpeed.fast);

    expect(controller.speed, ReadingSpeed.fast);
    expect(controller.isSpeaking, isTrue);
    expect(tts.stopCalls, 0);
    tts.finishSpeaking();
    await first;

    final second = controller.speak('B');
    expect(tts.spoken.last.speed, ReadingSpeed.fast);
    tts.finishSpeaking();
    await second;
  });

  test('8. fechar a tela durante a leitura para a voz', () async {
    await controller.prepare(portuguese);
    final reading = controller.speak('texto');

    controller.dispose();

    expect(tts.stopCalls, 1);
    await reading;
  });

  test('8b. fechar uma tela parada não corta a leitura de outra', () async {
    controller.dispose();

    expect(tts.stopCalls, 0);
  });

  test(
    '9. trocar o idioma do app vale para a disponibilidade e a leitura',
    () async {
      await controller.prepare(portuguese);
      expect(controller.isAvailable, isTrue);

      await controller.prepare(english);
      expect(controller.isAvailable, isFalse);

      tts.availableLanguages = {SpeechLanguage.ptBr, SpeechLanguage.enUs};
      final other = ReadAloudController(tts);
      await other.prepare(english);
      final reading = other.speak('hello');

      expect(tts.spoken.single.language, SpeechLanguage.enUs);
      tts.finishSpeaking();
      await reading;
    },
  );

  test('9b. o mesmo idioma não é consultado duas vezes', () async {
    await controller.prepare(portuguese);
    await controller.prepare(portuguese);

    expect(tts.availabilityChecks, 1);
    expect(controller.isAvailable, isTrue);
  });

  test('10. falha do motor volta a "parado" sem erro', () async {
    await controller.prepare(portuguese);
    final reading = controller.speak('texto');

    tts.failSpeaking();
    await reading;

    expect(controller.isSpeaking, isFalse);
  });

  test('texto vazio ou só com espaços não inicia leitura', () async {
    await controller.prepare(portuguese);

    await controller.speak('');
    await controller.speak('   ');

    expect(tts.spoken, isEmpty);
    expect(controller.isSpeaking, isFalse);
  });

  test('sem voz disponível, ouvir não chama o serviço', () async {
    await controller.speak('texto');

    tts.availableLanguages = {};
    await controller.prepare(portuguese);
    await controller.speak('texto');

    expect(tts.spoken, isEmpty);
  });

  group('velocidade guardada na acessibilidade (FR-012)', () {
    late AccessibilityPreferencesNotifier preferences;
    late ReadAloudController withPreferences;

    setUp(() async {
      preferences = AccessibilityPreferencesNotifier();
      preferences.value = preferences.value.copyWith(
        readingSpeed: ReadingSpeed.slow,
      );
      withPreferences = ReadAloudController(tts, preferences: preferences);
      await withPreferences.prepare(portuguese);
    });

    tearDown(() => withPreferences.dispose());

    test('começa na velocidade guardada', () async {
      expect(withPreferences.speed, ReadingSpeed.slow);

      unawaited(withPreferences.speak('texto'));

      expect(tts.spoken.single.speed, ReadingSpeed.slow);
    });

    test('mudar a preferência vale na próxima leitura', () async {
      preferences.value = preferences.value.copyWith(
        readingSpeed: ReadingSpeed.fast,
      );

      unawaited(withPreferences.speak('texto'));

      expect(tts.spoken.single.speed, ReadingSpeed.fast);
    });

    test('setSpeed da página vale só para ela, sem mudar a preferência', () {
      withPreferences.setSpeed(ReadingSpeed.normal);

      expect(withPreferences.speed, ReadingSpeed.normal);
      expect(preferences.value.readingSpeed, ReadingSpeed.slow);
    });
  });
}
