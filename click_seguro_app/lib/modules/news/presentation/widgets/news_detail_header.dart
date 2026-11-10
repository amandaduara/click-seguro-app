import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_detail_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_detail_presentation_extension.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_presentation_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_cover.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Cabeçalho do detalhe: imagem (se houver), categorias, título, "fonte ·
/// data" e curtidas (FR-001). O leitor de tela lê título, fonte e data.
class NewsDetailHeader extends StatelessWidget {
  const NewsDetailHeader({super.key, required this.detail, required this.now});

  static const double _imageHeight = 220;

  final NewsDetailEntity detail;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final List<String> categories = detail.news.categoryLabels();
    // Redesign 2.0 (Figma, quadro 05): capa grande com as categorias sobre
    // ela, título forte, fonte e curtidas.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NewsCover(
          imageUrl: detail.news.imageUrl,
          themeText: [
            ...detail.news.categories.map((c) => c.name),
            detail.news.title,
          ].join(' '),
          height: _imageHeight,
          radius: 24,
          labels: categories,
        ),
        const SizedBox(height: AppSpacing.s5),
        Semantics(
          header: true,
          label: detail.semanticLabel(now),
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.news.title,
                style: AppTypography.title1.copyWith(
                  color: colors.textForeground,
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                '${detail.news.source} · ${detail.news.relativeDate(now)}',
                style: AppTypography.caption.copyWith(
                  fontSize: 16,
                  color: colors.textMutedForeground,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Row(
          children: [
            Icon(
              LucideIcons.heart,
              size: 18,
              color: colors.textMutedForeground,
            ),
            const SizedBox(width: AppSpacing.s2),
            Flexible(
              child: Text(
                AppStrings.newsDetailLikes.tr(args: [detail.formattedLikes]),
                style: AppTypography.caption.copyWith(
                  fontSize: 16,
                  color: colors.textMutedForeground,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
