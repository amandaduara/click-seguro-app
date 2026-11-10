import 'package:flutter/services.dart';

/// Vibrações do app (specs/022 FR-021, FR-022, FR-028): uma por ação, sempre
/// por aqui. O aparelho ignora a vibração quando ela está desligada nele.
abstract final class AppHaptics {
  /// Curtir, alternar.
  static Future<void> selection() => HapticFeedback.selectionClick();

  /// Resposta certa.
  static Future<void> success() => HapticFeedback.lightImpact();

  /// Resposta errada.
  static Future<void> error() => HapticFeedback.heavyImpact();
}
