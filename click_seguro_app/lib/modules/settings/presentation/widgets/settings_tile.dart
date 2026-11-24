import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Linha das Configurações (redesign 2.0): ícone num círculo suave, título,
/// subtítulo e, à direita, um texto (ex.: o idioma) com a seta, ou o
/// [trailing] (ex.: a chave). [destructive] pinta a linha de vermelho e tira
/// a seta ("Sair da conta").
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  static const double minHeight = 64;

  /// Diâmetro do círculo do ícone.
  static const double iconCircle = 44;

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Texto à direita, antes da seta.
  final String? value;

  /// Substitui a seta (ex.: a chave de alertas).
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? sub = subtitle;
    final String? detail = value;
    final Color accent = destructive ? colors.destructive : colors.secondary;
    final Widget? end =
        trailing ??
        (destructive
            ? null
            : ExcludeSemantics(
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 22,
                  color: colors.textMutedForeground,
                ),
              ));
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
                  SettingsIconCircle(icon: icon, color: accent),
                  const SizedBox(width: AppSpacing.s4),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.bodyLarge?.copyWith(
                            fontSize: AppTypography.body.fontSize,
                            fontWeight: FontWeight.w700,
                            color: destructive
                                ? colors.destructive
                                : colors.textForeground,
                          ),
                        ),
                        if (sub != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            sub,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: AppTypography.caption.fontSize,
                              height: 1.35,
                              color: colors.textMutedForeground,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(width: AppSpacing.s2),
                    // A parte inteira do valor, com o texto à direita: assim a
                    // seta encosta no fim da linha (antes sobrava espaço
                    // vazio entre o valor e a seta).
                    Expanded(
                      flex: 2,
                      child: Text(
                        detail,
                        textAlign: TextAlign.end,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: AppTypography.caption.fontSize,
                          fontWeight: FontWeight.w600,
                          color: colors.textMutedForeground,
                        ),
                      ),
                    ),
                  ],
                  if (end != null) ...[
                    const SizedBox(width: AppSpacing.s2),
                    end,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// O círculo suave com o ícone das linhas: creme, ou branco com borda no alto
/// contraste (como o `SafeIconButton`). Decorativo para o leitor de tela.
class SettingsIconCircle extends StatelessWidget {
  const SettingsIconCircle({
    super.key,
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final bool highContrast = colors.shadow.isEmpty;
    return ExcludeSemantics(
      child: Container(
        width: SettingsTile.iconCircle,
        height: SettingsTile.iconCircle,
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: highContrast ? Border.all(color: colors.border) : null,
        ),
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}
