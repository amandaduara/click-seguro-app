import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_accessibility_preferences_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/save_accessibility_preferences_usecase.dart';
import 'package:flutter/foundation.dart';

/// Preferências de acessibilidade (RF-038 a RF-041). Carregado no
/// `setupApp()`, antes da primeira tela; a tela da B9 chama os `set`.
///
/// O valor em vigor fica no [AccessibilityPreferencesNotifier] de `common`,
/// lido pelo app (tema e escala) e pelos módulos de conteúdo.
class AccessibilityController extends ChangeNotifier {
  AccessibilityController({
    required GetAccessibilityPreferencesUseCase getPreferences,
    required SaveAccessibilityPreferencesUseCase savePreferences,
    required AccessibilityPreferencesNotifier notifier,
  }) : _getPreferences = getPreferences,
       _savePreferences = savePreferences,
       _notifier = notifier;

  final GetAccessibilityPreferencesUseCase _getPreferences;
  final SaveAccessibilityPreferencesUseCase _savePreferences;
  final AccessibilityPreferencesNotifier _notifier;

  /// Gravações em fila: a última escolha é a última gravada.
  Future<void> _pendingSave = Future.value();

  AccessibilityPreferences get preferences => _notifier.value;

  Future<void> load() async {
    _notifier.value = await _getPreferences();
    notifyListeners();
  }

  Future<void> setFontScale(FontScaleLevel fontScale) =>
      _update(preferences.copyWith(fontScale: fontScale));

  Future<void> setHighContrast(bool highContrast) =>
      _update(preferences.copyWith(highContrast: highContrast));

  Future<void> setAutoReadAloud(bool autoReadAloud) =>
      _update(preferences.copyWith(autoReadAloud: autoReadAloud));

  Future<void> setReadingSpeed(ReadingSpeed readingSpeed) =>
      _update(preferences.copyWith(readingSpeed: readingSpeed));

  /// Aplica na hora (FR-006) e grava em seguida. Se a gravação falhar, o valor
  /// vale até o app fechar (FR-009): não há o que mostrar à pessoa.
  Future<void> _update(AccessibilityPreferences next) {
    if (next == preferences) return _pendingSave;
    _notifier.value = next;
    notifyListeners();
    return _pendingSave = _pendingSave.then((_) => _savePreferences(next));
  }
}
