import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

enum SafeBadgeTone {
  primary,
  secondary,
  success,
  warning,
  destructive,
  neutral,

  /// Sobre uma imagem ou ilustração: branco com a sombra única.
  onImage,
}

/// SafeBadge — selo em pílula do redesign 2.0 (FR-007): fundo "suave" e
/// texto forte da mesma família, sempre com contraste AA (FR-001).
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

  ({Color bg, Color fg}) _colors(AppPalette c) => switch (tone) {
    SafeBadgeTone.primary => (bg: c.primarySoft, fg: c.primaryPressed),
    SafeBadgeTone.secondary => (bg: c.surfaceStrong, fg: c.textForeground),
    SafeBadgeTone.success => (bg: c.successSoft, fg: c.success),
    SafeBadgeTone.warning => (bg: c.warningSoft, fg: c.warning),
    SafeBadgeTone.destructive => (bg: c.primarySoft, fg: c.destructive),
    SafeBadgeTone.neutral => (bg: c.surfaceStrong, fg: c.textMutedForeground),
    SafeBadgeTone.onImage => (bg: c.card, fg: c.textForeground),
  };

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.colors;
    final colors = _colors(palette);
    final bool highContrast = palette.shadow.isEmpty;
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: AppSpacing.radiusFull,
        border: highContrast ? Border.all(color: colors.fg) : null,
        boxShadow: tone == SafeBadgeTone.onImage ? palette.shadow : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(color: colors.fg, size: 16),
              child: icon!,
            ),
            const SizedBox(width: 6),
          ],
          // Com letra grande, o texto quebra a linha em vez de estourar
          // (specs/015-painel-atividades). Por isso o selo precisa de largura
          // limitada: não colocar direto numa Row sem Expanded/Flexible.
          Flexible(
            child: DefaultTextStyle(
              style: AppTypography.caption.copyWith(
                color: colors.fg,
                fontWeight: FontWeight.w700,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
