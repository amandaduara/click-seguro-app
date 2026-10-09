import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_category_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Filtros de categoria do feed (design system §7.6): "Todas" seguido das
/// categorias ativas, numa faixa que rola para o lado.
class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selectedSlug,
    required this.onSelected,
  });

  final List<NewsCategoryEntity> categories;

  /// `null` = "Todas".
  final String? selectedSlug;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final chips = <(String label, String? slug)>[
      (AppStrings.newsFilterAll.tr(), null),
      for (final category in categories) (category.name, category.slug),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s2),
        itemBuilder: (_, index) {
          final (label, slug) = chips[index];
          return _FilterChip(
            label: label,
            selected: slug == selectedSlug,
            onTap: () => onSelected(slug),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? context.colors.secondary : context.colors.input,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? context.colors.textPrimaryForeground
                        : context.colors.textMutedForeground,
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
