import 'dart:ui' show Locale;

import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Motor de voz falso: guarda os handlers e as chamadas, e deixa o teste
/// disparar os avisos de início, fim, cancelamento e erro.
class _FakeFlutterTts extends Fake implements FlutterTts {
  final List<String> calls = [];
  final List<String> spokenTexts = [];

  Object? availableResult = true;
  bool failOnAvailable = false;
  Object? speakResult = 1;
  bool failOnSpeak = false;
  bool failOnStop = false;

  VoidCallback? _onStart;
  VoidCallback? _onComplete;
  VoidCallback? _onCancel;
  ErrorHandler? _onError;

  void start() => _onStart!();
  void complete() => _onComplete!();
  void cancel() => _onCancel!();
  void error() => _onError!('falha simulada');

  /// Simula uma parte lida do início ao fim.
  void startAndComplete() {
    start();
    complete();
  }

  @override
  void setStartHandler(VoidCallback callback) => _onStart = callback;

  @override
  void setCompletionHandler(VoidCallback callback) => _onComplete = callback;

  @override
  void setCancelHandler(VoidCallback callback) => _onCancel = callback;

  @override
  void setErrorHandler(ErrorHandler handler) => _onError = handler;

  @override
  Future<dynamic> isLanguageAvailable(String language) async {
    calls.add('isLanguageAvailable($language)');
    if (failOnAvailable) throw Exception('falha simulada');
    return availableResult;
  }

  @override
  Future<dynamic> stop() async {
    calls.add('stop');
    if (failOnStop) throw Exception('falha simulada');
    return 1;
  }

  @override
  Future<dynamic> setLanguage(String language) async {
    calls.add('setLanguage($language)');
    return 1;
  }

  @override
  Future<dynamic> setSpeechRate(double rate) async {
    calls.add('setSpeechRate($rate)');
    return 1;
  }

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    calls.add('speak');
    spokenTexts.add(text);
    if (failOnSpeak) throw Exception('falha simulada');
    return speakResult;
  }
}

/// Deixa o serviço avançar até ficar esperando o motor.
Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeFlutterTts tts;
  late FlutterTextToSpeechService service;

  setUp(() {
    tts = _FakeFlutterTts();
    service = FlutterTextToSpeechService(tts);
  });

  group('SpeechLanguage.fromLocale', () {
    test('português e qualquer outro idioma → ptBr', () {
      expect(
        SpeechLanguage.fromLocale(const Locale('pt', 'BR')),
        SpeechLanguage.ptBr,
      );
      expect(
        SpeechLanguage.fromLocale(const Locale('es')),
        SpeechLanguage.ptBr,
      );
    });

    test('inglês → enUs', () {
      expect(
        SpeechLanguage.fromLocale(const Locale('en', 'US')),
        SpeechLanguage.enUs,
      );
      expect(
        SpeechLanguage.fromLocale(const Locale('en')),
        SpeechLanguage.enUs,
      );
    });

    test('tags pt-BR e en-US', () {
      expect(SpeechLanguage.ptBr.tag, 'pt-BR');
      expect(SpeechLanguage.enUs.tag, 'en-US');
    });
  });

  group('isAvailable', () {
    test('consulta o idioma pela tag e devolve true quando há voz', () async {
      expect(await service.isAvailable(SpeechLanguage.ptBr), isTrue);
      expect(tts.calls, ['isLanguageAvailable(pt-BR)']);
    });

    test('false, null ou exceção → false', () async {
      tts.availableResult = false;
      expect(await service.isAvailable(SpeechLanguage.enUs), isFalse);

      tts.availableResult = null;
      expect(await service.isAvailable(SpeechLanguage.enUs), isFalse);

      tts.availableResult = true;
      tts.failOnAvailable = true;
      expect(await service.isAvailable(SpeechLanguage.enUs), isFalse);
    });
  });

  group('speak', () {
    test('para a anterior, ajusta idioma e velocidade e lê', () async {
      final reading = service.speak(
        'Olá',
        language: SpeechLanguage.enUs,
        speed: ReadingSpeed.slow,
      );
      await _flush();

      expect(tts.calls, [
        'stop',
        'setLanguage(en-US)',
        'setSpeechRate(0.4)',
        'speak',
      ]);
      expect(tts.spokenTexts, ['Olá']);

      tts.startAndComplete();
      expect(await reading, isTrue);
    });

    test('normal usa 0.5 e rápida usa 0.6', () async {
      final normal = service.speak(
        'a',
        language: SpeechLanguage.ptBr,
        speed: ReadingSpeed.normal,
      );
      await _flush();
      tts.startAndComplete();
      await normal;

      final fast = service.speak(
        'b',
        language: SpeechLanguage.ptBr,
        speed: ReadingSpeed.fast,
      );
      await _flush();
      tts.startAndComplete();
      await fast;

      expect(tts.calls, contains('setSpeechRate(0.5)'));
      expect(tts.calls, contains('setSpeechRate(0.6)'));
    });

    test('só completa depois do fim da leitura', () async {
      var done = false;
      final reading = service
          .speak(
            'Olá',
            language: SpeechLanguage.ptBr,
            speed: ReadingSpeed.normal,
          )
          .whenComplete(() => done = true);
      await _flush();
      expect(done, isFalse);

      tts.start();
      await _flush();
      expect(done, isFalse);

      tts.complete();
      expect(await reading, isTrue);
    });

    test('cancelamento depois do início → false', () async {
      final reading = service.speak(
        'Olá',
        language: SpeechLanguage.ptBr,
        speed: ReadingSpeed.normal,
      );
      await _flush();
      tts.start();
      tts.cancel();

      expect(await reading, isFalse);
    });

    test('erro → false, mesmo sem aviso de início', () async {
      final reading = service.speak(
        'Olá',
        language: SpeechLanguage.ptBr,
        speed: ReadingSpeed.normal,
      );
      await _flush();
      tts.error();

      expect(await reading, isFalse);
    });

    test('evento atrasado da leitura anterior não encerra a nova', () async {
      final first = service.speak(
        'A',
        language: SpeechLanguage.ptBr,
        speed: ReadingSpeed.normal,
      );
      await _flush();
      tts.start();

      var secondDone = false;
      final second = service
          .speak('B', language: SpeechLanguage.ptBr, speed: ReadingSpeed.normal)
          .whenComplete(() => secondDone = true);
      expect(await first, isFalse);
      await _flush();

      // Cancelamento de A chegando depois de B ter sido pedida.
      tts.cancel();
      await _flush();
      expect(secondDone, isFalse);

      tts.startAndComplete();
      expect(await second, isTrue);
    });

    test('speak do plugin devolvendo 0 → false sem esperar aviso', () async {
      tts.speakResult = 0;

      expect(
        await service.speak(
          'Olá',
          language: SpeechLanguage.ptBr,
          speed: ReadingSpeed.normal,
        ),
        isFalse,
      );
    });

    test('speak do plugin lançando → false', () async {
      tts.failOnSpeak = true;

      expect(
        await service.speak(
          'Olá',
          language: SpeechLanguage.ptBr,
          speed: ReadingSpeed.normal,
        ),
        isFalse,
      );
    });
  });

  group('texto longo', () {
    // Cerca de 9000 caracteres em frases de ~50.
    final sentences = [
      for (var i = 0; i < 180; i++)
        'Frase número $i com algumas palavras a mais.',
    ];
    final longText = sentences.join(' ');

    Future<bool> readAllParts(Future<bool> reading) async {
      for (var part = 0; part < 10; part++) {
        await _flush();
        tts.startAndComplete();
      }
      return reading;
    }

    test('é lido em partes de até 3900 caracteres, em fim de frase', () async {
      expect(longText.length, greaterThan(8000));

      var done = false;
      final reading = service
          .speak(
            longText,
            language: SpeechLanguage.ptBr,
            speed: ReadingSpeed.normal,
          )
          .whenComplete(() => done = true);
      await _flush();
      expect(tts.spokenTexts, hasLength(1));

      tts.startAndComplete();
      await _flush();
      expect(tts.spokenTexts, hasLength(2));
      expect(done, isFalse);

      tts.startAndComplete();
      await _flush();
      expect(tts.spokenTexts, hasLength(3));
      expect(done, isFalse);

      tts.startAndComplete();
      expect(await reading, isTrue);

      for (final part in tts.spokenTexts) {
        expect(part.length, lessThanOrEqualTo(3900));
        expect(part, endsWith('.'));
      }
      expect(tts.spokenTexts.join(' '), longText);
    });

    test('sem fim de frase, corta no último espaço', () async {
      final words = List.filled(1000, 'palavra').join(' ');

      expect(
        await readAllParts(
          service.speak(
            words,
            language: SpeechLanguage.ptBr,
            speed: ReadingSpeed.normal,
          ),
        ),
        isTrue,
      );

      expect(tts.spokenTexts.length, greaterThan(1));
      for (final part in tts.spokenTexts) {
        expect(part.length, lessThanOrEqualTo(3900));
        expect(part.split(' ').every((word) => word == 'palavra'), isTrue);
      }
      expect(tts.spokenTexts.join(' '), words);
    });

    test(
      'stop durante a primeira parte → false e não pede as outras',
      () async {
        final reading = service.speak(
          longText,
          language: SpeechLanguage.ptBr,
          speed: ReadingSpeed.normal,
        );
        await _flush();
        tts.start();

        await service.stop();
        expect(await reading, isFalse);

        await _flush();
        expect(tts.spokenTexts, hasLength(1));
      },
    );
  });

  group('stop', () {
    test('chama o stop do plugin', () async {
      await service.stop();

      expect(tts.calls, ['stop']);
    });

    test('não lança quando o plugin lança', () async {
      tts.failOnStop = true;

      await expectLater(service.stop(), completes);
    });
  });
}
