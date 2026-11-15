import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_detail_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/illustrations/illustration_theme.dart';
import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
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
    final SuggestedModuleEntity module = widget.module;
    final IllustrationTheme theme = IllustrationTheme.fromText(module.title);
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
        padded: false,
        onTap: _open,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, AppSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: AppSpacing.radiusMd,
                child: Container(
                  height: 130,
                  color: theme.pastel(context.colors),
                  padding: const EdgeInsets.all(AppSpacing.s3),
                  child: SafeIllustration(theme.illustration),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            heading,
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.colors.primary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s1),
                          Text(
                            module.title,
                            style: AppTypography.title3.copyWith(
                              fontWeight: FontWeight.w700,
                              color: context.colors.textForeground,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.s1),
                            Text(
                              description,
                              key: RelatedActivityCard.descriptionKey,
                              style: AppTypography.body.copyWith(
                                height: 1.4,
                                color: context.colors.textBody,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.s1),
                          Text(
                            questions,
                            style: AppTypography.caption.copyWith(
                              color: context.colors.textMutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.chevronRight,
                        color: context.colors.textForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
