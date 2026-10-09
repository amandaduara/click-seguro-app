import 'package:click_seguro_app/core/i18n/app_strings.dart';
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

  /// A aba do meio é o botão central redondo (Reels).
  bool get isCenter => this == AppTab.news;
}

/// Barra inferior do wireframe (design system §7.12).
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
          color: context.colors.background.withValues(alpha: 0.95),
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
                for (final tab in AppTab.values)
                  Expanded(
                    child: tab.isCenter
                        ? _CenterItem(
                            tab: tab,
                            selected: tab.index == currentIndex,
                            onTap: () => onSelected(tab.index),
                          )
                        : _TabItem(
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
    final Color color = selected
        ? context.colors.primary
        : context.colors.textMutedForeground;
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
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tab.icon, size: 20, color: color),
                const SizedBox(height: AppSpacing.s1),
                // Com fonte grande o rótulo reduz em vez de ser cortado.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
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

class _CenterItem extends StatelessWidget {
  const _CenterItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // heightFactor: 1 para não ocupar a altura toda da barra; o círculo sobe
    // um pouco acima da borda, como no wireframe.
    return Center(
      heightFactor: 1,
      child: Transform.translate(
        offset: const Offset(0, -AppSpacing.s4),
        child: Semantics(
          button: true,
          selected: selected,
          label: tab.labelKey.tr(),
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.colors.primary,
                shape: BoxShape.circle,
                boxShadow: context.colors.shadowPrimary,
                border: selected
                    ? Border.all(
                        color: context.colors.primary.withValues(alpha: 0.3),
                        width: 4,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      )
                    : null,
              ),
              child: Icon(
                tab.icon,
                size: 28,
                color: context.colors.textPrimaryForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
