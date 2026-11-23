import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/brand_scene.dart';
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

  final VoidCallback onCompleted;
  final bool breathing;

  @override
  State<SplashAnimation> createState() => _SplashAnimationState();
}

class _SplashAnimationState extends State<SplashAnimation>
    with TickerProviderStateMixin {
  /// Ciclo da respiração (ida e volta lenta), fora da escala de
  /// [AppMotion]: exceção registrada no design system para a splash.
  static const Duration _breathCycle = Duration(milliseconds: 2600);
  static const double _riseOffset = 14;

  late final AnimationController _scene = AnimationController(
    vsync: this,
    duration: SplashTimeline.total,
  )..addStatusListener(_onSceneStatus);
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: _breathCycle,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.of(context).reduced) {
      // Estado final direto: pula a cena (também se o ajuste mudar no meio).
      _scene.value = 1;
    } else if (_scene.isDismissed) {
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
    // A cena só avança: o "completed" chega uma única vez.
    if (status != AnimationStatus.completed) {
      return;
    }
    // Adiado para depois do quadro: pode vir de dentro do build (movimento
    // reduzido) e quem escuta atualiza a própria tela.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onCompleted();
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
    // Tipografia do redesign 2.0 (specs/024): título de tela e leitura.
    final TextStyle titleStyle = AppTypography.display.copyWith(
      color: colors.textForeground,
    );
    final TextStyle taglineStyle = AppTypography.bodyLarge.copyWith(
      color: colors.textBody,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final Rect logo = BrandScene.logoRectFor(
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
                      // Espaço da marca (a cena a desenha por cima) e o
                      // respiro até o nome, como no login (specs/026 R2).
                      SizedBox(height: BrandScene.titleTopFor(logo)),
                      _Rise(
                        animation: _scene,
                        interval: SplashTimeline.title,
                        child: Text(
                          AppStrings.appTitle.tr(),
                          textAlign: TextAlign.center,
                          style: titleStyle,
                        ),
                      ),
                      const SizedBox(height: BrandScene.taglineGap),
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
                      const SizedBox(
                        height: BrandScene.footerHeight + AppSpacing.s4,
                      ),
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
