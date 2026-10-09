import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
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
  bool _pressed = false;

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
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
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

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.99 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: card,
      ),
    );
  }
}
