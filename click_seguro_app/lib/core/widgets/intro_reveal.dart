import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/widgets/brand_scene.dart';
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

/// Faz a entrada animada de uma tela que começa onde a splash parou (o login
/// e o onboarding, specs/026): roda um progresso de 0 a 1 em [duration],
/// entrega-o aos [IntroReveal] da tela ([IntroScope]), ignora toques até o
/// fim e desenha por cima as camadas de [overlay] (o que sai da splash), que
/// recebem o progresso e onde a marca estava no fim da splash. Com o
/// movimento reduzido, nasce pronta.
class IntroHost extends StatefulWidget {
  const IntroHost({
    super.key,
    required this.duration,
    required this.overlay,
    required this.child,
  });

  final Duration duration;
  final List<Widget> Function(BuildContext context, double t, Rect splashLogo)
  overlay;
  final Widget child;

  @override
  State<IntroHost> createState() => _IntroHostState();
}

class _IntroHostState extends State<IntroHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.of(context).reduced) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IntroScope(
    animation: _controller,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final Rect splashLogo = BrandScene.logoRectFor(
          width: constraints.maxWidth,
          viewportHeight: constraints.maxHeight,
          topInset: MediaQuery.paddingOf(context).top,
        );
        return AnimatedBuilder(
          animation: _controller,
          child: widget.child,
          builder: (context, child) {
            final double t = _controller.value;
            return Stack(
              children: [
                IgnorePointer(ignoring: t < 1, child: child),
                ...widget.overlay(context, t, splashLogo),
              ],
            );
          },
        );
      },
    ),
  );
}

/// O nome e o slogan da splash saindo: com [progress] de 0 a 1, sobem [rise]
/// px a partir do lugar deles ao lado de [splashLogo] e somem. Vai direto
/// num `Stack` (é um `Positioned`).
class LeavingBrandTitle extends StatelessWidget {
  const LeavingBrandTitle({
    super.key,
    required this.splashLogo,
    required this.progress,
    required this.rise,
  });

  final Rect splashLogo;
  final double progress;
  final double rise;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    top: BrandScene.titleTopFor(splashLogo) - rise * progress,
    child: Opacity(opacity: 1 - progress, child: const BrandTitle()),
  );
}
