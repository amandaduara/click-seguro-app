import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/modules/splash/presentation/widgets/splash_scene_painter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Abertura "Mancha e onda" (specs/023): toca uma vez ao montar e avisa em
/// [onCompleted] quando chega ao estado final. Com o movimento reduzido, já
/// nasce no estado final, sem tocar nem respirar.
///
/// Com [breathing], a marca respira devagar (1 a 1,035) até a página sair.
class SplashAnimation extends StatefulWidget {
  const SplashAnimation({
    super.key,
    required this.onCompleted,
    required this.breathing,
  });

  /// Espaço da marca no layout; a cena a desenha por cima dele.
  static const ValueKey<String> logoKey = ValueKey('splash.logo');

  final VoidCallback? onCompleted;
  final bool breathing;

  @override
  State<SplashAnimation> createState() => _SplashAnimationState();
}

class _SplashAnimationState extends State<SplashAnimation>
    with TickerProviderStateMixin {
  static const Duration _breathCycle = Duration(milliseconds: 2600);
  static const double _riseOffset = 14;
  static const double _afterLogoGap = 36;
  static const double _afterTitleGap = 10;

  late final AnimationController _scene = AnimationController(
    vsync: this,
    duration: SplashTimeline.total,
  )..addStatusListener(_onSceneStatus);
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: _breathCycle,
  );

  bool _started = false;
  bool _completionNotified = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.of(context).reduced) {
      // Estado final direto: pula a cena (também se o ajuste mudar no meio).
      _scene.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _scene.forward();
    }
    _syncBreath();
  }

  @override
  void didUpdateWidget(SplashAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBreath();
  }

  void _syncBreath() {
    if (widget.breathing && !AppMotion.of(context).reduced) {
      if (!_breath.isAnimating) {
        _breath.repeat(reverse: true);
      }
    } else {
      _breath.stop();
    }
  }

  void _onSceneStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _completionNotified) {
      return;
    }
    _completionNotified = true;
    // Adiado para depois do quadro: pode vir de dentro do build (movimento
    // reduzido) e quem escuta atualiza a própria tela.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onCompleted?.call();
      }
    });
  }

  @override
  void dispose() {
    _scene.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle? titleStyle = textTheme.displayLarge?.copyWith(
      fontSize: 34,
      height: 40 / 34,
      letterSpacing: -0.68,
      color: colors.secondary,
    );
    final TextStyle? taglineStyle = textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w500,
      height: 24 / 16,
      color: colors.textMutedForeground,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final Rect logo = SplashScenePainter.logoRectFor(
          width: constraints.maxWidth,
          viewportHeight: constraints.maxHeight,
          topInset: MediaQuery.paddingOf(context).top,
        );
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_scene, _breath]),
                    builder: (context, _) => CustomPaint(
                      painter: SplashScenePainter(
                        t: _scene.value,
                        breath: Curves.easeInOut.transform(_breath.value),
                        colors: colors,
                        logoRect: logo,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      SizedBox(height: logo.top),
                      SizedBox(
                        key: SplashAnimation.logoKey,
                        width: logo.width,
                        height: logo.height,
                      ),
                      const SizedBox(height: _afterLogoGap),
                      _Rise(
                        animation: _scene,
                        interval: SplashTimeline.title,
                        child: Text(
                          AppStrings.appTitle.tr(),
                          textAlign: TextAlign.center,
                          style: titleStyle,
                        ),
                      ),
                      const SizedBox(height: _afterTitleGap),
                      _Rise(
                        animation: _scene,
                        interval: SplashTimeline.tagline,
                        child: Text(
                          AppStrings.splashTagline.tr(),
                          textAlign: TextAlign.center,
                          style: taglineStyle,
                        ),
                      ),
                      // Deixa o texto livre da onda do rodapé ao rolar.
                      const SizedBox(height: 126),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Sobe 14 px e aparece no [interval] da cena.
class _Rise extends StatelessWidget {
  const _Rise({
    required this.animation,
    required this.interval,
    required this.child,
  });

  final Animation<double> animation;
  final Interval interval;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) {
      final double progress = interval.transform(animation.value);
      return Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, _SplashAnimationState._riseOffset * (1 - progress)),
          child: child,
        ),
      );
    },
  );
}
