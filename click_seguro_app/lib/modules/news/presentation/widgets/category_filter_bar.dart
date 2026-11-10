import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_category_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/widgets/safe_chip.dart';
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

  // Chip do redesign 2.0 (FR-007).
  @override
  Widget build(BuildContext context) =>
      SafeChip(label: label, selected: selected, onTap: onTap);
}
