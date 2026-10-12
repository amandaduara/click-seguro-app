import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/profile/presentation/extensions/count_format.dart';
import 'package:flutter/material.dart';

/// Um dos números do perfil (lidas, salvas ou curtidas), que abre a lista.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final int count;
  final String label;

  /// Ex.: "12 notícias lidas, abrir lista".
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.radius2xl,
          side: BorderSide(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s2,
              vertical: AppSpacing.s4,
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(height: AppSpacing.s2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatCount(count),
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: colors.secondary,
                    ),
                  ),
                ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textMutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
