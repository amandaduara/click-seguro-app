import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/press_scale.dart';
import 'package:flutter/material.dart';

enum SafeCardElevation { flat, sm, md }

/// SafeCard — cartão do redesign 2.0 (FR-004): branco, canto 20 e a sombra
/// única; `flat` é creme e sem sombra. No alto contraste, borda no lugar da
/// sombra. Tocável: encolhe para 98% (FR-020), sem movimento com reduzir
/// animações (FR-021), e é lido como botão (specs/022 FR-007).
class SafeCard extends StatelessWidget {
  const SafeCard({
    super.key,
    required this.child,
    this.elevation = SafeCardElevation.sm,
    this.padded = true,
    this.interactive = false,
    this.onTap,
  });

  final Widget child;
  final SafeCardElevation elevation;
  final bool padded;
  final bool interactive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final bool flat = elevation == SafeCardElevation.flat;
    final bool highContrast = colors.shadow.isEmpty;

    final Widget card = AnimatedContainer(
      duration: AppMotion.of(context).short,
      curve: AppMotion.standard,
      padding: padded ? const EdgeInsets.all(AppSpacing.s5) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: flat ? colors.surface : colors.card,
        borderRadius: AppSpacing.radiusLg,
        border: highContrast ? Border.all(color: colors.border) : null,
        boxShadow: flat ? null : colors.shadow,
      ),
      child: child,
    );

    if (!interactive) return card;

    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      child: PressScale(
        enabled: onTap != null,
        pressedScale: 0.98,
        onTap: onTap,
        child: card,
      ),
    );
  }
}
