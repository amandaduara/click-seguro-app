import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/safe_badge.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_presentation_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Topo da folha branca do detalhe (redesign 2.0, Figma quadro 05): selos
/// das categorias, título grande e "fonte · data · tempo de leitura"
/// (FR-001). A capa e os botões sobre ela ficam no `NewsDetailCoverBar`.
///
/// Também mostra a prévia do cartão enquanto o detalhe carrega (specs/022
/// R9): sem [readingMinutes], o tempo de leitura fica de fora até chegar.
class NewsDetailHeader extends StatelessWidget {
  const NewsDetailHeader({
    super.key,
    required this.news,
    required this.now,
    this.readingMinutes,
  });

  final NewsItemEntity news;
  final DateTime now;

  /// Minutos de leitura do texto; `null` antes da carga ou sem texto.
  final int? readingMinutes;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final List<String> labels = news.categoryLabels();
    final int? minutes = readingMinutes;
    final String? readingTime = minutes == null
        ? null
        : AppStrings.newsDetailReadingTime.tr(args: ['$minutes']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (labels.isNotEmpty) ...[
          // Nó próprio: as categorias são lidas antes do título, sem se
          // juntar a ele.
          Semantics(
            container: true,
            child: Wrap(
              spacing: AppSpacing.s2,
              runSpacing: AppSpacing.s2,
              children: [
                for (int i = 0; i < labels.length; i++)
                  SafeBadge(
                    // A primeira categoria em coral, as outras em creme.
                    tone: i == 0
                        ? SafeBadgeTone.primary
                        : SafeBadgeTone.secondary,
                    child: Text(labels[i]),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
        ],
        Semantics(
          container: true,
          header: true,
          label: [news.headerLabel(now), ?readingTime].join(', '),
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                news.title,
                style: AppTypography.title1.copyWith(
                  color: colors.textForeground,
                ),
              ),
              const SizedBox(height: AppSpacing.s3),
              Text(
                [news.source, news.relativeDate(now), ?readingTime].join(' · '),
                style: AppTypography.caption.copyWith(
                  color: colors.textMutedForeground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
