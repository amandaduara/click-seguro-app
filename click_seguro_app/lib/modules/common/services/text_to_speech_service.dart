import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter_tts/flutter_tts.dart';

/// Velocidade da leitura em voz alta (RF-015).
enum ReadingSpeed { slow, normal, fast }

/// Idioma da voz: o mesmo do app (RF-042).
enum SpeechLanguage {
  ptBr('pt-BR'),
  enUs('en-US');

  const SpeechLanguage(this.tag);

  final String tag;

  /// Inglês → [enUs]; qualquer outro idioma cai em [ptBr], como os textos do
  /// app.
  static SpeechLanguage fromLocale(Locale locale) =>
      locale.languageCode == 'en' ? enUs : ptBr;
}

/// Leitura em voz alta pelo motor de voz do aparelho (RF-015, RF-040).
///
/// Nenhum método lança: falhas viram `false` (CB-008, FR-017).
abstract class TextToSpeechService {
  /// Há voz para [language] no aparelho. Sem motor, sem voz ou erro → false.
  Future<bool> isAvailable(SpeechLanguage language);

  /// Para a leitura anterior e lê [text]. Completa quando a leitura termina:
  /// `true` = até o fim; `false` = interrompida por [stop], por outro [speak]
  /// ou por falha.
  Future<bool> speak(
    String text, {
    required SpeechLanguage language,
    required ReadingSpeed speed,
  });

  Future<void> stop();
}

/// Implementação com `flutter_tts` (ver specs/007-servicos-plataforma-voz,
/// research R2).
///
/// O fim de cada leitura vem dos avisos do motor. Fim e cancelamento só valem
/// depois do aviso de início da leitura atual: o cancelamento de uma leitura
/// interrompida pode chegar depois que a nova já foi pedida.
class FlutterTextToSpeechService implements TextToSpeechService {
  FlutterTextToSpeechService([FlutterTts? tts]) : _tts = tts ?? FlutterTts() {
    _tts.setStartHandler(() => _started = true);
    _tts.setCompletionHandler(() {
      if (_started) _completePending(true);
    });
    _tts.setCancelHandler(() {
      if (_started) _completePending(false);
    });
    _tts.setErrorHandler((_) => _completePending(false));
  }

  /// O Android recusa textos acima de 4000 caracteres
  /// (`TextToSpeech.getMaxSpeechInputLength`); textos maiores são lidos em
  /// partes.
  static const int _maxChunkLength = 3900;

  /// Retorno do `speak` do plugin quando o motor recusa o texto.
  static const int _speakFailed = 0;

  static const String _sentenceEnds = '.!?\n';

  final FlutterTts _tts;

  Completer<bool>? _pending;
  bool _started = false;

  /// Identifica a leitura atual; [speak] e [stop] o incrementam para encerrar
  /// a leitura em partes que estiver em andamento.
  int _reading = 0;

  @override
  Future<bool> isAvailable(SpeechLanguage language) async {
    try {
      return await _tts.isLanguageAvailable(language.tag) == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> speak(
    String text, {
    required SpeechLanguage language,
    required ReadingSpeed speed,
  }) async {
    final int reading = ++_reading;
    _completePending(false);
    try {
      await _tts.stop();
      await _tts.setLanguage(language.tag);
      await _tts.setSpeechRate(_rateFor(speed));

      final List<String> chunks = _split(text);
      if (chunks.isEmpty) return false;
      for (final String chunk in chunks) {
        if (reading != _reading) return false;
        final Completer<bool> pending = Completer<bool>();
        _pending = pending;
        _started = false;
        if (await _tts.speak(chunk) == _speakFailed) {
          if (reading == _reading) _completePending(false);
          return false;
        }
        if (!await pending.future) return false;
      }
      return reading == _reading;
    } catch (_) {
      if (reading == _reading) _completePending(false);
      return false;
    }
  }

  @override
  Future<void> stop() async {
    _reading++;
    _completePending(false);
    try {
      await _tts.stop();
    } catch (_) {
      // Nada a fazer: a leitura já foi marcada como encerrada.
    }
  }

  void _completePending(bool finished) {
    final Completer<bool>? pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(finished);
  }

  /// Valores do `flutter_tts`: 0.5 é a velocidade padrão no Android e no iOS
  /// (research R4).
  static double _rateFor(ReadingSpeed speed) => switch (speed) {
    ReadingSpeed.slow => 0.4,
    ReadingSpeed.normal => 0.5,
    ReadingSpeed.fast => 0.6,
  };

  /// Divide [text] em partes de até [_maxChunkLength] caracteres, cortando no
  /// último fim de frase ou, sem ele, no último espaço.
  static List<String> _split(String text) {
    final List<String> chunks = [];
    String rest = text.trim();
    while (rest.length > _maxChunkLength) {
      final String window = rest.substring(0, _maxChunkLength);
      int cut = _lastSentenceEnd(window) + 1;
      if (cut <= 0) cut = window.lastIndexOf(' ');
      if (cut <= 0) cut = _maxChunkLength;
      chunks.add(rest.substring(0, cut).trim());
      rest = rest.substring(cut).trim();
    }
    if (rest.isNotEmpty) chunks.add(rest);
    return chunks;
  }

  static int _lastSentenceEnd(String window) {
    int last = -1;
    for (final String end in _sentenceEnds.split('')) {
      final int index = window.lastIndexOf(end);
      if (index > last) last = index;
    }
    return last;
  }
}
