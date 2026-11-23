import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/widgets/brand_mark.dart';
import 'package:click_seguro_app/core/widgets/brand_scene.dart';
import 'package:click_seguro_app/core/widgets/intro_reveal.dart';
import 'package:flutter/material.dart';

/// De onde o login veio, quando ele abre com uma passagem animada.
enum LoginIntroOrigin {
  /// A marca voa da splash até o cabeçalho (specs/026 R1).
  splash,

  /// A onda sobe do pé da tela e a marca do cabeçalho cresce (US5).
  onboarding,
}

/// Linha do tempo da entrada do login (specs/026 R1 e US5).
/// Tempos fixos da passagem aprovada (fora da escala de `AppMotion`, como a
/// `SplashTimeline`); o movimento reduzido pula a entrada inteira.
abstract final class _LoginIntroTimeline {
  static const Duration total = Duration(milliseconds: 1250);

  static double _at(int ms) => ms / total.inMilliseconds;

  /// Vindo da splash: o nome e o slogan da splash somem subindo.
  static final Interval splashText = Interval(
    0,
    _at(300),
    curve: AppMotion.exit,
  );

  /// Vindo da splash: a marca vai do lugar da splash ao cabeçalho (curva da
  /// splash).
  static final Interval flight = Interval(
    _at(150),
    _at(750),
    curve: Curves.fastOutSlowIn,
  );

  /// Vindo do onboarding: a onda sobe do pé da tela até o lugar dela.
  static final Interval waveIn = Interval(0, _at(500), curve: AppMotion.enter);

  /// Vindo do onboarding: a marca do cabeçalho cresce.
  static final Interval logoIn = Interval(
    _at(150),
    _at(550),
    curve: AppMotion.enter,
  );

  /// Entrada do bloco [index] do login (0 a 4), 125 ms depois do anterior.
  static Interval step(int index) => Interval(
    _at(450 + 125 * index),
    _at(750 + 125 * index),
    curve: AppMotion.enter,
  );
}

/// Faz a entrada do login quando ele vem da splash ou do onboarding: os
/// blocos ([LoginIntroReveal]) entram em sequência e, conforme a [origin],
/// a marca voa da splash até o cabeçalho ([LoginIntroLogoSlot]) ou a onda
/// sobe ([LoginIntroWave]). Enquanto anima, ignora toques. Com o movimento
/// reduzido, nasce pronta.
class LoginIntro extends StatefulWidget {
  const LoginIntro({super.key, required this.origin, required this.child});

  final LoginIntroOrigin origin;
  final Widget child;

  @override
  State<LoginIntro> createState() => _LoginIntroState();
}

class _LoginIntroState extends State<LoginIntro>
    with SingleTickerProviderStateMixin {
  static const double _textExitOffset = 10;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _LoginIntroTimeline.total,
  );
  final GlobalKey _logoSlot = GlobalKey();

  /// Onde a marca termina (o espaço dela no cabeçalho), medido depois do
  /// primeiro quadro.
  Rect? _target;

  bool get _fromSplash => widget.origin == LoginIntroOrigin.splash;

  @override
  void initState() {
    super.initState();
    if (_fromSplash) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureTarget());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.of(context).reduced) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  void _measureTarget() {
    final RenderObject? slot = _logoSlot.currentContext?.findRenderObject();
    final RenderObject? stack = context.findRenderObject();
    if (!mounted || slot is! RenderBox || stack is! RenderBox) return;
    setState(() {
      _target = slot.localToGlobal(Offset.zero, ancestor: stack) & slot.size;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IntroScope(
      animation: _controller,
      child: _LoginIntroScope(
        origin: widget.origin,
        animation: _controller,
        logoSlotKey: _logoSlot,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final Rect start = BrandScene.logoRectFor(
              width: constraints.maxWidth,
              viewportHeight: constraints.maxHeight,
              topInset: MediaQuery.paddingOf(context).top,
            );
            return AnimatedBuilder(
              animation: _controller,
              child: widget.child,
              builder: (context, child) {
                final double t = _controller.value;
                final double flight = _LoginIntroTimeline.flight.transform(t);
                final double textExit = _LoginIntroTimeline.splashText
                    .transform(t);
                return Stack(
                  children: [
                    IgnorePointer(ignoring: t < 1, child: child),
                    if (_fromSplash && textExit < 1)
                      Positioned(
                        left: 0,
                        right: 0,
                        top:
                            BrandScene.titleTopFor(start) -
                            _textExitOffset * textExit,
                        child: Opacity(
                          opacity: 1 - textExit,
                          child: const BrandTitle(),
                        ),
                      ),
                    if (_fromSplash && flight < 1)
                      Positioned.fromRect(
                        rect: Rect.lerp(start, _target ?? start, flight)!,
                        child: const BrandMark(),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LoginIntroScope extends InheritedWidget {
  const _LoginIntroScope({
    required this.origin,
    required this.animation,
    required this.logoSlotKey,
    required super.child,
  });

  final LoginIntroOrigin origin;
  final Animation<double> animation;
  final GlobalKey logoSlotKey;

  static _LoginIntroScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LoginIntroScope>();

  @override
  bool updateShouldNotify(_LoginIntroScope oldWidget) =>
      origin != oldWidget.origin ||
      animation != oldWidget.animation ||
      logoSlotKey != oldWidget.logoSlotKey;
}

/// Bloco do login que entra subindo 14 px no passo [step] da entrada. Fora
/// da entrada, mostra [child] como está.
class LoginIntroReveal extends StatelessWidget {
  const LoginIntroReveal({super.key, required this.step, required this.child});

  final int step;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      IntroReveal(interval: _LoginIntroTimeline.step(step), child: child);
}

/// Espaço da marca no cabeçalho. Vindo da splash, é o destino do voo e fica
/// vazio até a marca chegar; vindo do onboarding, a marca cresce no lugar.
/// Fora da entrada, mostra [child] como está.
class LoginIntroLogoSlot extends StatelessWidget {
  const LoginIntroLogoSlot({super.key, required this.child});

  static const double _logoScaleFrom = 0.6;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final _LoginIntroScope? scope = _LoginIntroScope.maybeOf(context);
    if (scope == null) return child;
    if (scope.origin == LoginIntroOrigin.onboarding) {
      return IntroReveal(
        interval: _LoginIntroTimeline.logoIn,
        rise: 0,
        scaleFrom: _logoScaleFrom,
        child: child,
      );
    }
    return KeyedSubtree(
      key: scope.logoSlotKey,
      child: AnimatedBuilder(
        animation: scope.animation,
        child: child,
        builder: (context, child) => Opacity(
          opacity:
              _LoginIntroTimeline.flight.transform(scope.animation.value) >= 1
              ? 1
              : 0,
          child: child,
        ),
      ),
    );
  }
}

/// A onda do login. Vindo do onboarding, sobe do pé da tela até o lugar
/// dela; nos outros casos, fica parada.
class LoginIntroWave extends StatelessWidget {
  const LoginIntroWave({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final _LoginIntroScope? scope = _LoginIntroScope.maybeOf(context);
    if (scope == null || scope.origin != LoginIntroOrigin.onboarding) {
      return child;
    }
    return AnimatedBuilder(
      animation: scope.animation,
      child: child,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          0,
          BrandScene.glowFooterHeight *
              (1 - _LoginIntroTimeline.waveIn.transform(scope.animation.value)),
        ),
        child: child,
      ),
    );
  }
}
