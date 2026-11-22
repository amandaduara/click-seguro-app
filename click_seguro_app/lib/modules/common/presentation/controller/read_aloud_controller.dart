import 'dart:async';
import 'dart:ui' show Locale;

import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:flutter/foundation.dart';

/// Um trecho de leitura. [content] = texto do banco (notícia, lição,
/// contato, Reel), lido na voz de [ReadAloudController.contentLanguage];
/// senão, texto do próprio app, lido no idioma do app.
@immutable
class SpeechPart {
  const SpeechPart(this.text, {this.content = false});

  final String text;
  final bool content;
}

/// Estado do botão "Ouvir" de uma página (A5, B2): disponibilidade da voz,
/// leitura em andamento e velocidade (RF-015, CB-008).
///
/// Um por página (factory no `CommonModule`); a página chama
/// [prepare] com o idioma do app e descarta o controller ao fechar.
class ReadAloudController extends ChangeNotifier {
  ReadAloudController(
    this._tts, {
    AccessibilityPreferencesNotifier? preferences,
  }) : _preferences = preferences;

  final TextToSpeechService _tts;

  /// Idioma do conteúdo que vem do banco: a API só tem textos em português.
  /// Com o app em inglês, esse conteúdo continua lido com voz em português,
  /// para não sair com sotaque (validação da usuária, specs/025).
  static const SpeechLanguage contentLanguage = SpeechLanguage.ptBr;

  /// Velocidade guardada na acessibilidade (FR-012 da feature 009).
  final AccessibilityPreferencesNotifier? _preferences;

  final Map<SpeechLanguage, bool> _availability = {};
  SpeechLanguage? _language;
  bool _isSpeaking = false;

  /// Escolhida na própria página; vale só para ela.
  ReadingSpeed? _pageSpeed;
  bool _disposed = false;

  /// Identifica a leitura atual: o fim de uma leitura substituída é ignorado.
  int _generation = 0;

  /// Há voz no idioma preparado. Fica `false` até a verificação terminar, para
  /// o botão não aparecer antes da hora.
  bool get isAvailable => _availability[_language] ?? false;

  /// Há voz para o conteúdo do banco ([contentLanguage]). Telas que só leem
  /// conteúdo (notícia, Reel) mostram o botão por aqui.
  bool get isContentAvailable => _availability[contentLanguage] ?? false;

  /// Uma leitura iniciada por este controller está em andamento.
  bool get isSpeaking => _isSpeaking;

  /// Velocidade da próxima leitura: a da página, se escolhida; senão a das
  /// preferências de acessibilidade.
  ReadingSpeed get speed =>
      _pageSpeed ?? _preferences?.value.readingSpeed ?? ReadingSpeed.normal;

  /// Usa o idioma do app ([locale]) para a disponibilidade e as próximas
  /// leituras; também confere a voz do conteúdo ([contentLanguage]). Cada
  /// idioma é consultado uma vez.
  Future<void> prepare(Locale locale) async {
    final SpeechLanguage language = SpeechLanguage.fromLocale(locale);
    _language = language;
    for (final SpeechLanguage needed in {language, contentLanguage}) {
      if (_availability.containsKey(needed)) continue;
      final bool available = await _tts.isAvailable(needed);
      if (_disposed) return;
      _availability[needed] = available;
    }
    notifyListeners();
  }

  /// Lê [text], interrompendo a leitura anterior. Com [content], é texto do
  /// banco e sai na voz de [contentLanguage]. Ignora texto vazio e voz
  /// indisponível (FR-007, CB-008).
  Future<void> speak(String text, {bool content = false}) =>
      speakParts([SpeechPart(text, content: content)]);

  /// Lê as partes em ordem, cada uma no seu idioma, interrompendo a leitura
  /// anterior. Partes vazias ou sem voz no aparelho são puladas; parar (ou
  /// outra leitura) encerra as que faltam.
  Future<void> speakParts(List<SpeechPart> parts) async {
    final SpeechLanguage? appLanguage = _language;
    if (appLanguage == null) return;
    final List<(String, SpeechLanguage)> readable = [
      for (final SpeechPart part in parts)
        if (part.text.trim().isNotEmpty &&
            (_availability[part.content ? contentLanguage : appLanguage] ??
                false))
          (part.text, part.content ? contentLanguage : appLanguage),
    ];
    if (readable.isEmpty) return;

    final int generation = ++_generation;
    _setSpeaking(true);
    for (final (String text, SpeechLanguage language) in readable) {
      final bool finished = await _tts.speak(
        text,
        language: language,
        speed: speed,
      );
      if (!finished || generation != _generation) break;
    }
    if (generation == _generation) _setSpeaking(false);
  }

  /// O motor recebe o "parar" antes do aviso: quem ouve o "parado" pode
  /// começar outra leitura na hora (leitura automática da próxima pergunta),
  /// e ela não pode ser cancelada por este parar (revisão de specs/017).
  Future<void> stop() async {
    _generation++;
    final Future<void> stopping = _tts.stop();
    _setSpeaking(false);
    await stopping;
  }

  void setSpeed(ReadingSpeed speed) {
    _pageSpeed = speed;
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
