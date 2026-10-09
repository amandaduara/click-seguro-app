import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:flutter/foundation.dart';

/// Preferências de acessibilidade em vigor. Fica em `common` para que o app,
/// `news` e `activities` leiam sem importar `settings`; quem muda é o
/// `AccessibilityController` (plano do produto §3.2).
class AccessibilityPreferencesNotifier
    extends ValueNotifier<AccessibilityPreferences> {
  AccessibilityPreferencesNotifier()
    : super(const AccessibilityPreferences.defaults());
}
