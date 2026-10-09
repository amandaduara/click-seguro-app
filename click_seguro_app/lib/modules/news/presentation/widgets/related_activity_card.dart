import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_detail_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Bloco "Pratique o que aprendeu" do detalhe (FR-021): título, descrição e
/// número de perguntas do módulo sugerido; tocar abre o módulo.
class RelatedActivityCard extends StatefulWidget {
  const RelatedActivityCard({
    super.key,
    required this.module,
    required this.onTap,
  });

  static const Key cardKey = ValueKey('related-activity');
  static const Key descriptionKey = ValueKey('related-activity-description');

  final SuggestedModuleEntity module;

  /// Abre o módulo; toques novos são ignorados até o futuro terminar.
  final Future<void> Function() onTap;

  @override
  State<RelatedActivityCard> createState() => _RelatedActivityCardState();
}

class _RelatedActivityCardState extends State<RelatedActivityCard> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    _opening = true;
    try {
      await widget.onTap();
    } finally {
      if (mounted) _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final SuggestedModuleEntity module = widget.module;
    final String heading = AppStrings.newsDetailRelatedTitle.tr();
    final String questions = AppStrings.newsDetailRelatedQuestions.tr(
      args: ['${module.lessonsCount}'],
    );
    final String description = module.description.trim();
    return Semantics(
      button: true,
      label: [
        heading,
        module.title,
        if (description.isNotEmpty) description,
        questions,
      ].join(', '),
      excludeSemantics: true,
      child: SafeCard(
        key: RelatedActivityCard.cardKey,
        interactive: true,
        onTap: _open,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading,
                    style: textTheme.labelLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textMutedForeground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    module.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textForeground,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      description,
                      key: RelatedActivityCard.descriptionKey,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        color: context.colors.textForeground,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    questions,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: context.colors.textMutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Icon(
              LucideIcons.chevronRight,
              color: context.colors.textMutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}
