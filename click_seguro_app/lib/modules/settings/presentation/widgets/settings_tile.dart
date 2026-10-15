import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Linha das Configurações: ícone num quadrado claro, título, subtítulo e,
/// à direita, um texto (ex.: o idioma) ou a seta.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
  });

  static const double minHeight = 64;

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Texto à direita, antes da seta.
  final String? value;

  /// Substitui a seta (ex.: a chave de alertas).
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? sub = subtitle;
    final String? detail = value;
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s4,
                vertical: AppSpacing.s3,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.secondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 22, color: colors.secondary),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.textForeground,
                          ),
                        ),
                        if (sub != null)
                          Text(
                            sub,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: colors.textMutedForeground,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(width: AppSpacing.s2),
                    Flexible(
                      child: Text(
                        detail,
                        textAlign: TextAlign.end,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: colors.textMutedForeground,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: AppSpacing.s2),
                  trailing ??
                      ExcludeSemantics(
                        child: Icon(
                          LucideIcons.chevronRight,
                          size: 20,
                          color: colors.textMutedForeground,
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
