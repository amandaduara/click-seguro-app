import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/widgets/brand_mark.dart';
import 'package:click_seguro_app/core/widgets/brand_scene.dart';
import 'package:click_seguro_app/core/widgets/intro_reveal.dart';
import 'package:flutter/material.dart';

/// Linha do tempo da passagem da splash para o onboarding (specs/026 US5,
/// FR-020). Tempos fixos da passagem aprovada (fora da escala de
/// `AppMotion`, como a `SplashTimeline`); o movimento reduzido pula tudo.
abstract final class OnboardingIntroTimeline {
  static const Duration total = Duration(milliseconds: 1000);

  static double _at(int ms) => ms / total.inMilliseconds;

  /// A marca, o nome e o slogan da splash sobem e somem.
  static final Interval splashOut = Interval(
    0,
    _at(350),
    curve: AppMotion.exit,
  );

  /// A onda desce e sai pelo pé da tela.
  static final Interval waveOut = Interval(0, _at(450), curve: AppMotion.exit);

  /// A ilustração do slide aparece crescendo de leve.
  static final Interval illustration = Interval(
    _at(300),
    _at(700),
    curve: AppMotion.enter,
  );

  /// Título, "Ouvir" e texto do slide.
  static final Interval text = Interval(
    _at(450),
    _at(800),
    curve: AppMotion.enter,
  );

  /// Pontinhos do indicador.
  static final Interval dots = Interval(
    _at(550),
    _at(850),
    curve: AppMotion.enter,
  );

  /// Botão principal.
  static final Interval button = Interval(
    _at(600),
    _at(900),
    curve: AppMotion.enter,
  );

  /// "Pular".
  static final Interval skip = Interval(
    _at(700),
    _at(1000),
    curve: AppMotion.enter,
  );
}

/// Faz a entrada do onboarding quando ele vem da splash: o primeiro quadro é
/// o último da splash; a marca, o nome e o slogan sobem e somem, a onda desce
/// e sai, e os blocos do slide (os `IntroReveal` com os intervalos de
/// [OnboardingIntroTimeline]) entram em sequência. Enquanto anima, ignora
/// toques. Com o movimento reduzido, nasce pronta.
class OnboardingIntro extends StatefulWidget {
  const OnboardingIntro({super.key, required this.child});

  final Widget child;

  @override
  State<OnboardingIntro> createState() => _OnboardingIntroState();
}

class _OnboardingIntroState extends State<OnboardingIntro>
    with SingleTickerProviderStateMixin {
  static const double _exitRise = 16;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: OnboardingIntroTimeline.total,
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
  Widget build(BuildContext context) {
    return IntroScope(
      animation: _controller,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final Rect logo = BrandScene.logoRectFor(
            width: constraints.maxWidth,
            viewportHeight: constraints.maxHeight,
            topInset: MediaQuery.paddingOf(context).top,
          );
          return AnimatedBuilder(
            animation: _controller,
            child: widget.child,
            builder: (context, child) {
              final double t = _controller.value;
              final double out = OnboardingIntroTimeline.splashOut.transform(t);
              final double wave = OnboardingIntroTimeline.waveOut.transform(t);
              final Offset rise = Offset(0, -_exitRise * out);
              return Stack(
                children: [
                  IgnorePointer(ignoring: t < 1, child: child),
                  if (out < 1) ...[
                    Positioned.fromRect(
                      rect: logo.shift(rise),
                      child: Opacity(
                        opacity: 1 - out,
                        child: const BrandMark(),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: BrandScene.titleTopFor(logo) + rise.dy,
                      child: Opacity(
                        opacity: 1 - out,
                        child: const BrandTitle(),
                      ),
                    ),
                  ],
                  if (wave < 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -BrandScene.glowFooterHeight * wave,
                      child: const BrandWave(),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
