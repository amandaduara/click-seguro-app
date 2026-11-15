import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Abas em pílula do redesign 2.0 (FR-007): trilho creme e a aba atual
/// branca com a sombra única. Cada aba diz ao leitor de tela se está
/// selecionada. Com fonte grande, o rótulo encolhe.
///
/// O fundo branco é um indicador só, que desliza para a aba nova: com um
/// fundo animado por aba, as duas ficavam meio preenchidas na troca e
/// pareciam piscar (validação da usuária, specs/024).
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
    final AppMotion motion = AppMotion.of(context);
    final bool highContrast = colors.shadow.isEmpty;
    final int count = tabs.length;
    final double x = count < 2 ? 0 : -1 + 2 * selectedIndex / (count - 1);
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      // 4 + aba de 48 + 4: os 56 do trilho, com cada aba tocável em 48
      // (RNF-003).
      padding: const EdgeInsets.all(AppSpacing.s1),
      decoration: BoxDecoration(
        color: colors.surfaceStrong,
        borderRadius: AppSpacing.radiusFull,
        border: highContrast ? Border.all(color: colors.border) : null,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              alignment: Alignment(x, 0),
              duration: motion.medium,
              curve: AppMotion.standard,
              child: FractionallySizedBox(
                widthFactor: 1 / count,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: AppSpacing.radiusFull,
                    boxShadow: colors.shadow,
                    border: highContrast
                        ? Border.all(color: colors.border, width: 2)
                        : null,
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (int i = 0; i < count; i++)
                Expanded(
                  child: _Tab(
                    label: tabs[i],
                    selected: i == selectedIndex,
                    onTap: () => onChanged(i),
                  ),
                ),
            ],
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
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          // Numa linha só: em telas estreitas com fonte muito grande, o
          // rótulo encolhe o necessário em vez de quebrar no meio da palavra.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedDefaultTextStyle(
              duration: AppMotion.of(context).medium,
              curve: AppMotion.standard,
              style: AppTypography.label.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected
                    ? colors.textForeground
                    : colors.textMutedForeground,
              ),
              child: Text(label, maxLines: 1, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}
