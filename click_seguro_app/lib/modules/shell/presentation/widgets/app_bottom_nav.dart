import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
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

/// Barra inferior do redesign 2.0 (FR-009; design system §7.12).
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
              AppSpacing.s3,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Cinco abas iguais, sem o botão central de antes: ele
                // confundia em qual aba a pessoa estava (FR-009 de
                // specs/022-redesign-visual).
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

  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final String label = tab.labelKey.tr();
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Indicador em pílula atrás do ícone (FR-009).
              AnimatedContainer(
                duration: AppMotion.duration(
                  AppMotion.fast,
                  reduce: context.reduceMotion,
                ),
                width: 60,
                height: 34,
                decoration: BoxDecoration(
                  color: selected ? colors.primarySoft : Colors.transparent,
                  borderRadius: AppSpacing.radiusFull,
                  border: selected && colors.shadow.isEmpty
                      ? Border.all(color: colors.primary, width: 2)
                      : null,
                ),
                child: Icon(
                  tab.icon,
                  size: 26,
                  color: selected ? colors.primary : colors.textMutedForeground,
                ),
              ),
              const SizedBox(height: AppSpacing.s1),
              // Rótulo de 15 (mínimo do FR-003); com fonte grande quebra em
              // até duas linhas em vez de sumir.
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? colors.textForeground
                      : colors.textMutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
