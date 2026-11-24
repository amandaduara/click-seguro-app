import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Chip de filtro do redesign 2.0 (FR-007): pílula creme de 48 de altura; selecionado fica
/// invertido em tinta. A seleção também vai para o leitor de tela.
class SafeChip extends StatelessWidget {
  const SafeChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final Color fg = selected
        ? colors.textPrimaryForeground
        : colors.textForeground;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      enabled: onTap != null,
      // Sem isto o excludeSemantics tira a ação do InkWell e o leitor de
      // tela não consegue tocar no chip.
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? colors.secondary : colors.surface,
            borderRadius: AppSpacing.radiusFull,
            border: colors.shadow.isEmpty
                ? Border.all(color: colors.border)
                : null,
          ),
          child: InkWell(
            borderRadius: AppSpacing.radiusFull,
            onTap: onTap,
            child: ConstrainedBox(
              // 48: alvo de toque mínimo (RNF-003).
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.label.copyWith(color: fg),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
