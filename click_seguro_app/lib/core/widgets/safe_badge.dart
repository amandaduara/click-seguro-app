import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum SafeBadgeTone { primary, secondary, success, warning, destructive, neutral }

/// SafeBadge — rótulo compacto cujo fundo é exatamente 10% de opacidade
/// da cor do texto selecionada (ex.: bg-success/10 text-success).
class SafeBadge extends StatelessWidget {
  const SafeBadge({
    super.key,
    required this.child,
    this.tone = SafeBadgeTone.primary,
    this.icon,
  });

  final Widget child;
  final SafeBadgeTone tone;
  final Widget? icon;

  Color get _color {
    switch (tone) {
      case SafeBadgeTone.primary:
        return AppColors.primary;
      case SafeBadgeTone.secondary:
        return AppColors.secondary;
      case SafeBadgeTone.success:
        return AppColors.success;
      case SafeBadgeTone.warning:
        return AppColors.warning;
      case SafeBadgeTone.destructive:
        return AppColors.destructive;
      case SafeBadgeTone.neutral:
        return AppColors.textMutedForeground;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: tone == SafeBadgeTone.neutral ? AppColors.textMutedForeground : color.withOpacity(0.1),
        borderRadius: AppSpacing.radiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            IconTheme(data: IconThemeData(color: color, size: 12), child: icon!),
            const SizedBox(width: 4),
          ],
          DefaultTextStyle(
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
