import 'package:flutter/widgets.dart';

/// Entrega aos [IntroReveal] de uma tela o progresso (0 a 1) da entrada dela,
/// quando ela abre com uma passagem animada (specs/026: a splash leva ao
/// onboarding ou ao login, o onboarding leva ao login). Sem um [IntroScope]
/// acima, os [IntroReveal] mostram o filho como está.
class IntroScope extends InheritedWidget {
  const IntroScope({super.key, required this.animation, required super.child});

  final Animation<double> animation;

  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<IntroScope>()?.animation;

  @override
  bool updateShouldNotify(IntroScope oldWidget) =>
      animation != oldWidget.animation;
}

/// Um bloco que entra no trecho [interval] da entrada: aparece subindo
/// [rise] px e, com [scaleFrom], crescendo dessa escala até 1 (só na pintura;
/// o layout não muda).
class IntroReveal extends StatelessWidget {
  const IntroReveal({
    super.key,
    required this.interval,
    this.rise = 14,
    this.scaleFrom,
    required this.child,
  });

  final Interval interval;
  final double rise;
  final double? scaleFrom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Animation<double>? animation = IntroScope.maybeOf(context);
    if (animation == null) return child;
    final double? scaleFrom = this.scaleFrom;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final double progress = interval.transform(animation.value);
        Widget shown = child!;
        if (scaleFrom != null) {
          shown = Transform.scale(
            scale: scaleFrom + (1 - scaleFrom) * progress,
            child: shown,
          );
        }
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, rise * (1 - progress)),
            child: shown,
          ),
        );
      },
    );
  }
}
