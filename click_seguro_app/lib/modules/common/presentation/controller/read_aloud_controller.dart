import 'dart:async';
import 'dart:ui' show Locale;

import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:flutter/foundation.dart';

/// Estado do botão "Ouvir" de uma página (A5, B2): disponibilidade da voz,
/// leitura em andamento e velocidade (RF-015, CB-008).
///
/// Um por página (factory no `CommonModule`); a página chama
/// [prepare] com o idioma do app e descarta o controller ao fechar.
class ReadAloudController extends ChangeNotifier {
  ReadAloudController(this._tts);

  final TextToSpeechService _tts;

  final Map<SpeechLanguage, bool> _availability = {};
  SpeechLanguage? _language;
  bool _isSpeaking = false;
  ReadingSpeed _speed = ReadingSpeed.normal;
  bool _disposed = false;

  /// Identifica a leitura atual: o fim de uma leitura substituída é ignorado.
  int _generation = 0;

  /// Há voz no idioma preparado. Fica `false` até a verificação terminar, para
  /// o botão não aparecer antes da hora.
  bool get isAvailable => _availability[_language] ?? false;

  /// Uma leitura iniciada por este controller está em andamento.
  bool get isSpeaking => _isSpeaking;

  /// Velocidade da próxima leitura.
  ReadingSpeed get speed => _speed;

  /// Usa o idioma do app ([locale]) para a disponibilidade e as próximas
  /// leituras. Cada idioma é consultado uma vez.
  Future<void> prepare(Locale locale) async {
    final SpeechLanguage language = SpeechLanguage.fromLocale(locale);
    _language = language;
    if (!_availability.containsKey(language)) {
      final bool available = await _tts.isAvailable(language);
      if (_disposed) return;
      _availability[language] = available;
    }
    notifyListeners();
  }

  /// Lê [text], interrompendo a leitura anterior. Ignora texto vazio e voz
  /// indisponível (FR-007, CB-008).
  Future<void> speak(String text) async {
    final SpeechLanguage? language = _language;
    if (language == null || !isAvailable || text.trim().isEmpty) return;

    final int generation = ++_generation;
    _setSpeaking(true);
    await _tts.speak(text, language: language, speed: _speed);
    if (generation == _generation) _setSpeaking(false);
  }

  Future<void> stop() async {
    _generation++;
    _setSpeaking(false);
    await _tts.stop();
  }

  void setSpeed(ReadingSpeed speed) {
    _speed = speed;
    notifyListeners();
  }

  /// Para a leitura só se for deste controller: o motor é um só, e a página
  /// seguinte pode já estar lendo (research R3).
  @override
  void dispose() {
    _disposed = true;
    _generation++;
    if (_isSpeaking) unawaited(_tts.stop());
    super.dispose();
  }

  void _setSpeaking(bool value) {
    if (_disposed || _isSpeaking == value) return;
    _isSpeaking = value;
    notifyListeners();
  }
}
