import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/intro_reveal.dart';
import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/models/onboarding_page_content.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/widgets/onboarding_intro.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Slide do onboarding no redesign 2.0 (Figma, quadro 02): ilustração
/// grande, que flutua devagar, e o título e o texto alinhados à esquerda.
/// Rola quando a letra grande não cabe. [listen] (o "Ouvir") fica logo
/// abaixo do título, antes do texto.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({super.key, required this.content, this.listen});

  final OnboardingPageContent content;
  final Widget? listen;

  /// Na entrada vinda da splash, a ilustração cresce desta escala até 1.
  static const double _illustrationScaleFrom = 0.92;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntroReveal(
                interval: OnboardingIntroTimeline.illustration,
                rise: 0,
                scaleFrom: _illustrationScaleFrom,
                child: _Floating(
                  child: SafeIllustration(
                    content.illustration,
                    height: (constraints.maxHeight * .5).clamp(160, 300),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s7),
              IntroReveal(
                interval: OnboardingIntroTimeline.text,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.titleKey.tr(),
                      style: AppTypography.display.copyWith(
                        color: context.colors.textForeground,
                      ),
                    ),
                    if (listen case final Widget listen) ...[
                      const SizedBox(height: AppSpacing.s3),
                      listen,
                    ],
                    const SizedBox(height: AppSpacing.s3),
                    Text(
                      content.descriptionKey.tr(),
                      style: AppTypography.bodyLarge.copyWith(
                        color: context.colors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sobe e desce 6 px a cada 3 s (FR-020); parado com reduzir animações.
class _Floating extends StatefulWidget {
  const _Floating({required this.child});

  final Widget child;

  @override
  State<_Floating> createState() => _FloatingState();
}

class _FloatingState extends State<_Floating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.of(context).reduced) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      // Poucas voltas, para a tela poder "assentar" (como o "Ouvir").
      _controller.repeat(reverse: true, count: 4);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -6 * Curves.easeInOut.transform(_controller.value)),
        child: child,
      ),
    ),
  );
}
