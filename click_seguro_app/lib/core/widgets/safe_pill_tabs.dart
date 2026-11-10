import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Abas em pílula do redesign 2.0 (FR-007): trilho creme e a aba atual
/// branca com a sombra única. Cada aba diz ao leitor de tela se está
/// selecionada. Com fonte grande, o rótulo quebra a linha.
class SafePillTabs extends StatelessWidget {
  const SafePillTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final bool highContrast = colors.shadow.isEmpty;
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colors.surfaceStrong,
        borderRadius: AppSpacing.radiusFull,
        border: highContrast ? Border.all(color: colors.border) : null,
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++)
            Expanded(
              child: _Tab(
                label: tabs[i],
                selected: i == selectedIndex,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.of(context).short,
          constraints: const BoxConstraints(minHeight: 46),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? colors.card : Colors.transparent,
            borderRadius: AppSpacing.radiusFull,
            boxShadow: selected ? colors.shadow : null,
            border: selected && colors.shadow.isEmpty
                ? Border.all(color: colors.border, width: 2)
                : null,
          ),
          // Numa linha só: em telas estreitas com fonte muito grande, o
          // rótulo encolhe o necessário em vez de quebrar no meio da palavra.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(
                fontSize: 17,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected
                    ? colors.textForeground
                    : colors.textMutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
