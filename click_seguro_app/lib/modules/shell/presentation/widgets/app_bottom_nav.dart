import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Abas da área principal, na ordem da barra inferior e das branches do
/// `StatefulShellRoute` (data-model de specs/005-shell-navegacao-base).
enum AppTab {
  home(AppStrings.shellTabHome, LucideIcons.house),
  activities(AppStrings.shellTabActivities, LucideIcons.graduationCap),
  news(AppStrings.shellTabNews, LucideIcons.newspaper),
  help(AppStrings.shellTabHelp, LucideIcons.lifeBuoy),
  profile(AppStrings.shellTabProfile, LucideIcons.user);

  const AppTab(this.labelKey, this.icon);

  final String labelKey;
  final IconData icon;
}

/// Barra inferior do redesign 2.0 (FR-009; design system §7.12): só os
/// ícones, com a aba ativa num círculo coral.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: AppStrings.shellNavLabel.tr(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.card,
          border: Border(top: BorderSide(color: context.colors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s2,
              AppSpacing.s2,
              AppSpacing.s2,
              AppSpacing.s2,
            ),
            child: Row(
              children: [
                // Cinco abas iguais, sem o botão central de antes: ele
                // confundia em qual aba a pessoa estava (FR-009 de
                // specs/024-redesign-visual).
                for (final tab in AppTab.values)
                  Expanded(
                    child: _TabItem(
                      tab: tab,
                      selected: tab.index == currentIndex,
                      onTap: () => onSelected(tab.index),
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

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  /// Diâmetro do círculo coral da aba ativa.
  static const double _circle = 44;

  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final AppMotion motion = AppMotion.of(context);
    // Só o ícone na barra; o nome da aba fica para o leitor de tela e para
    // o toque longo (dica).
    final String label = tab.labelKey.tr();
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        // Sem isto o excludeSemantics tira a ação do InkResponse e o leitor
        // de tela não consegue trocar de aba.
        onTap: onTap,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 32,
          child: SizedBox(
            height: 56,
            child: Center(
              // A aba ativa fica num círculo coral com o ícone branco, como o
              // antigo botão central, só que menor.
              child: AnimatedContainer(
                duration: motion.short,
                curve: AppMotion.standard,
                width: _circle,
                height: _circle,
                decoration: BoxDecoration(
                  color: selected ? colors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: selected ? colors.shadow : null,
                ),
                // A cor do ícone muda com animação curta (specs/022 FR-025).
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(
                    end: selected
                        ? colors.textPrimaryForeground
                        : colors.textMutedForeground,
                  ),
                  duration: motion.short,
                  curve: AppMotion.standard,
                  builder: (context, color, _) =>
                      Icon(tab.icon, size: 24, color: color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
