import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum SafeCardElevation { flat, sm, md }

/// SafeCard — cartão do redesign 2.0 (FR-004): branco, canto 20 e a sombra
/// única; `flat` é creme e sem sombra. No alto contraste, borda no lugar da
/// sombra. Tocável: encolhe para 98% (FR-020), sem movimento com reduzir
/// animações (FR-021).
class SafeCard extends StatefulWidget {
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
  State<SafeCard> createState() => _SafeCardState();
}

class _SafeCardState extends State<SafeCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final bool flat = widget.elevation == SafeCardElevation.flat;
    final bool highContrast = colors.shadow.isEmpty;
    final bool reduceMotion = context.reduceMotion;

    final Widget card = AnimatedContainer(
      duration: AppMotion.duration(AppMotion.fast, reduce: reduceMotion),
      padding: widget.padded
          ? const EdgeInsets.all(AppSpacing.s5)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: flat ? colors.surface : colors.card,
        borderRadius: AppSpacing.radiusLg,
        border: highContrast ? Border.all(color: colors.border) : null,
        boxShadow: flat ? null : colors.shadow,
      ),
      child: widget.child,
    );

    if (!widget.interactive) return card;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed && !reduceMotion ? 0.98 : 1.0,
        duration: AppMotion.duration(AppMotion.fast, reduce: reduceMotion),
        curve: AppMotion.enter,
        child: card,
      ),
    );
  }
}
