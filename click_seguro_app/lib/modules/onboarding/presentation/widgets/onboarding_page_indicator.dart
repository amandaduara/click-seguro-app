import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Pontos das páginas; o ativo é mais largo. Com [controller], acompanha o
/// arraste: a largura e a cor seguem a página fracionária (specs/022
/// FR-024).
class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
    this.controller,
  });

  static const double _dot = 8;
  static const double _active = 24;

  final int pageCount;
  final int currentPage;
  final PageController? controller;

  /// A página na tela, fracionária durante o arraste.
  double _page() {
    final PageController? pages = controller;
    if (pages == null || !pages.hasClients) return currentPage.toDouble();
    final ScrollPosition position = pages.position;
    if (!position.hasContentDimensions || !position.hasViewportDimension) {
      return currentPage.toDouble();
    }
    return pages.page ?? currentPage.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final PageController? pages = controller;
    if (pages == null) return _dots(context, currentPage.toDouble());
    return AnimatedBuilder(
      animation: pages,
      builder: (context, _) => _dots(context, _page()),
    );
  }

  Widget _dots(BuildContext context, double page) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(pageCount, (index) {
      // 1 no ponto da página, 0 a uma página ou mais de distância.
      final double t = (1 - (page - index).abs()).clamp(0.0, 1.0);
      return AnimatedContainer(
        key: ValueKey('onboarding-dot-$index'),
        // Seguindo o dedo, sem atraso; sem controlador, anima a troca.
        duration: controller == null
            ? AppMotion.of(context).medium
            : Duration.zero,
        curve: AppMotion.standard,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s1),
        width: _dot + (_active - _dot) * t,
        height: _dot,
        decoration: BoxDecoration(
          color: Color.lerp(context.colors.border, context.colors.primary, t),
          borderRadius: AppSpacing.radiusFull,
        ),
      );
    }),
  );
}
