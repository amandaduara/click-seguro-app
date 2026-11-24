import 'package:flutter/material.dart';

/// Durações e curvas de toda animação de interface (design system §6,
/// specs/022 FR-008). Com o movimento reduzido, todas as durações valem zero:
/// o código da animação é o mesmo e a troca vira imediata (FR-010).
///
/// Widgets leem sempre por [AppMotion.of], nunca com durações literais.
@immutable
final class AppMotion {
  const AppMotion._({required this.reduced});

  static const AppMotion normal = AppMotion._(reduced: false);
  static const AppMotion reducedMotion = AppMotion._(reduced: true);

  /// "Reduzir animações" do app ou "remover animações" do aparelho.
  final bool reduced;

  /// Pressão de botão, troca de cor de um ícone.
  Duration get short =>
      reduced ? Duration.zero : const Duration(milliseconds: 150);

  /// Troca de estado, de aba, entrada de mensagens.
  Duration get medium =>
      reduced ? Duration.zero : const Duration(milliseconds: 250);

  /// Entrada de tela, pulso do curtir. Teto de 400 ms (spec, US2).
  Duration get long =>
      reduced ? Duration.zero : const Duration(milliseconds: 350);

  /// O que entra na tela.
  static const Curve enter = Easing.emphasizedDecelerate;

  /// O que sai da tela.
  static const Curve exit = Easing.emphasizedAccelerate;

  /// Troca no lugar (cor, opacidade, tamanho).
  static const Curve standard = Easing.standard;

  /// Ênfase curta (pulso), com um leve passar do ponto.
  static const Curve emphasis = Curves.easeOutBack;

  /// O movimento em vigor: o do [AppMotionScope] acima ou, sem ele, só o
  /// "remover animações" do aparelho.
  static AppMotion of(BuildContext context) {
    final bool reduced =
        context
            .dependOnInheritedWidgetOfExactType<_AppMotionInherited>()
            ?.reduced ??
        MediaQuery.maybeDisableAnimationsOf(context) ??
        false;
    return reduced ? reducedMotion : normal;
  }
}

/// Junta o "Reduzir animações" do app (Acessibilidade) com o "remover
/// animações" do aparelho, para todas as telas abaixo.
class AppMotionScope extends StatelessWidget {
  const AppMotionScope({
    super.key,
    required this.appReduceMotion,
    required this.child,
  });

  final bool appReduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) => _AppMotionInherited(
    reduced: appReduceMotion || MediaQuery.disableAnimationsOf(context),
    child: child,
  );
}

class _AppMotionInherited extends InheritedWidget {
  const _AppMotionInherited({required this.reduced, required super.child});

  final bool reduced;

  @override
  bool updateShouldNotify(_AppMotionInherited oldWidget) =>
      reduced != oldWidget.reduced;
}
