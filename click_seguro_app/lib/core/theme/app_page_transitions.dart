import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Transição das telas empilhadas com `push` (specs/022 FR-015): a do
/// [animated] (volta preditiva no Android) ou, com o movimento reduzido, o
/// corte seco (FR-010).
class MotionAwareTransitionsBuilder extends PageTransitionsBuilder {
  const MotionAwareTransitionsBuilder(this.animated);

  final PageTransitionsBuilder animated;

  @override
  Duration get transitionDuration => animated.transitionDuration;

  @override
  Duration get reverseTransitionDuration => animated.reverseTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => AppMotion.of(context).reduced
      ? MotionCut(animation: animation, child: child)
      : animated.buildTransitions(
          route,
          context,
          animation,
          secondaryAnimation,
          child,
        );
}

/// Troca seca de uma rota. A duração da rota é fixada quando ela é criada;
/// sem animar, a tela que sai ainda ficaria por cima até o fim da transição.
/// Por isso ela some já no primeiro quadro da volta.
class MotionCut extends AnimatedWidget {
  const MotionCut({
    super.key,
    required Animation<double> animation,
    required this.child,
  }) : super(listenable: animation);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AnimationStatus status = (listenable as Animation<double>).status;
    return Visibility(
      visible:
          status == AnimationStatus.forward ||
          status == AnimationStatus.completed,
      maintainState: true,
      child: child,
    );
  }
}
