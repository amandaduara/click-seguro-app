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

/// Faz a entrada do login quando ele vem da splash ou do onboarding
/// ([IntroHost]): os blocos ([LoginIntroReveal]) entram em sequência e,
/// conforme a [origin], a marca voa da splash até o cabeçalho
/// ([LoginIntroLogoSlot]) ou a onda sobe ([LoginIntroWave]).
class LoginIntro extends StatefulWidget {
  const LoginIntro({super.key, required this.origin, required this.child});

  final LoginIntroOrigin origin;
  final Widget child;

  @override
  State<LoginIntro> createState() => _LoginIntroState();
}

class _LoginIntroState extends State<LoginIntro> {
  static const double _textExitRise = 10;

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

  void _measureTarget() {
    final RenderObject? slot = _logoSlot.currentContext?.findRenderObject();
    final RenderObject? host = context.findRenderObject();
    if (!mounted || slot is! RenderBox || host is! RenderBox) return;
    setState(() {
      _target = slot.localToGlobal(Offset.zero, ancestor: host) & slot.size;
    });
  }

  @override
  Widget build(BuildContext context) => _LoginIntroScope(
    origin: widget.origin,
    logoSlotKey: _logoSlot,
    child: IntroHost(
      duration: _LoginIntroTimeline.total,
      overlay: (context, t, splashLogo) {
        if (!_fromSplash) return const [];
        final double flight = _LoginIntroTimeline.flight.transform(t);
        final double textExit = _LoginIntroTimeline.splashText.transform(t);
        return [
          if (textExit < 1)
            LeavingBrandTitle(
              splashLogo: splashLogo,
              progress: textExit,
              rise: _textExitRise,
            ),
          if (flight < 1)
            Positioned.fromRect(
              rect: Rect.lerp(splashLogo, _target ?? splashLogo, flight)!,
              child: const BrandMark(),
            ),
        ];
      },
      child: widget.child,
    ),
  );
}

class _LoginIntroScope extends InheritedWidget {
  const _LoginIntroScope({
    required this.origin,
    required this.logoSlotKey,
    required super.child,
  });

  final LoginIntroOrigin origin;
  final GlobalKey logoSlotKey;

  static _LoginIntroScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LoginIntroScope>();

  @override
  bool updateShouldNotify(_LoginIntroScope oldWidget) =>
      origin != oldWidget.origin || logoSlotKey != oldWidget.logoSlotKey;
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
    final Animation<double>? animation = IntroScope.maybeOf(context);
    if (scope == null || animation == null) return child;
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
        animation: animation,
        child: child,
        builder: (context, child) => Opacity(
          opacity: _LoginIntroTimeline.flight.transform(animation.value) >= 1
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
    final Animation<double>? animation = IntroScope.maybeOf(context);
    if (animation == null ||
        _LoginIntroScope.maybeOf(context)?.origin !=
            LoginIntroOrigin.onboarding) {
      return child;
    }
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          0,
          BrandScene.glowFooterHeight *
              (1 - _LoginIntroTimeline.waveIn.transform(animation.value)),
        ),
        child: child,
      ),
    );
  }
}
