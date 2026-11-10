import 'package:flutter/material.dart';

/// Durações e curvas das animações do redesign (R8 e R9 de
/// specs/023-redesign-visual).
///
/// Toda animação consulta [AppMotionContext.reduceMotion]: o `main.dart` soma
/// o "Reduzir animações" do app ao do aparelho em
/// `MediaQuery.disableAnimations` (FR-021, FR-024).
abstract final class AppMotion {
  /// Toque, troca de cor, chips.
  static const Duration fast = Duration(milliseconds: 150);

  /// Troca de tela e de aba.
  static const Duration standard = Duration(milliseconds: 250);

  /// Folha inferior e progresso.
  static const Duration emphasis = Duration(milliseconds: 400);

  /// Confete e contagem do placar.
  static const Duration celebration = Duration(milliseconds: 1200);

  static const Curve enter = Cubic(0.2, 0, 0, 1);
  static const Curve exit = Cubic(0.4, 0, 1, 1);

  /// Mola leve: passa um pouco do ponto e volta.
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1);

  /// [base], ou zero quando as animações estão desligadas.
  static Duration duration(Duration base, {required bool reduce}) =>
      reduce ? Duration.zero : base;
}

extension AppMotionContext on BuildContext {
  /// Animações desligadas pelo aparelho ou pelo app.
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;
}
