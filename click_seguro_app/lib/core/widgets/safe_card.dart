import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/press_scale.dart';
import 'package:flutter/material.dart';

enum SafeCardElevation { flat, sm, md }

/// SafeCard — contêiner com bordas arredondadas (rounded-3xl), elevação e
/// modo interativo (hover: shadow-md · active: scale 0.99).
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
  List<BoxShadow>? get _shadow {
    if (widget.interactive) return context.colors.shadowMd;
    switch (widget.elevation) {
      case SafeCardElevation.flat:
        return null;
      case SafeCardElevation.sm:
        return context.colors.shadowSm;
      case SafeCardElevation.md:
        return context.colors.shadowMd;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppMotion motion = AppMotion.of(context);
    final card = AnimatedContainer(
      duration: motion.short,
      curve: AppMotion.standard,
      padding: widget.padded
          ? const EdgeInsets.all(AppSpacing.s5)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: context.colors.card,
        border: Border.all(color: context.colors.border),
        borderRadius: AppSpacing.radius3xl,
        boxShadow: _shadow,
      ),
      child: widget.child,
    );

    if (!widget.interactive) return card;

    return Semantics(
      container: true,
      button: true,
      enabled: widget.onTap != null,
      child: PressScale(
        enabled: true,
        pressedScale: 0.99,
        onTap: widget.onTap,
        child: card,
      ),
    );
  }
}
