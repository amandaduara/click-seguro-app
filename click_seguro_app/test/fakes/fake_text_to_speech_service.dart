import 'dart:async';

import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';

/// Voz em memória para testes. Como o motor real, uma leitura nova ou um
/// [stop] encerram a leitura pendente com `false`.
class FakeTextToSpeechService implements TextToSpeechService {
  FakeTextToSpeechService({Set<SpeechLanguage>? availableLanguages})
    : availableLanguages = availableLanguages ?? {...SpeechLanguage.values};

  /// Idiomas com voz no "aparelho".
  Set<SpeechLanguage> availableLanguages;

  int availabilityChecks = 0;
  int stopCalls = 0;

  final List<({String text, SpeechLanguage language, ReadingSpeed speed})>
  spoken = [];

  Completer<bool>? _pending;

  /// Termina a leitura pendente até o fim.
  void finishSpeaking() => _complete(true);

  /// Faz a leitura pendente falhar.
  void failSpeaking() => _complete(false);

  @override
  Future<bool> isAvailable(SpeechLanguage language) async {
    availabilityChecks++;
    return availableLanguages.contains(language);
  }

  @override
  Future<bool> speak(
    String text, {
    required SpeechLanguage language,
    required ReadingSpeed speed,
  }) {
    _complete(false);
    spoken.add((text: text, language: language, speed: speed));
    final pending = Completer<bool>();
    _pending = pending;
    return pending.future;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _complete(false);
  }

  void _complete(bool finished) {
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(finished);
  }
}
