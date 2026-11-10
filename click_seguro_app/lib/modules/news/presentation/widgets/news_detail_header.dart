import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_presentation_extension.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_cover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Cabeçalho do detalhe (redesign 2.0, Figma quadro 05): capa grande com as
/// categorias sobre ela, título forte, "fonte · data" e curtidas (FR-001).
/// O leitor de tela lê título, fonte e data.
///
/// Também mostra a prévia do cartão enquanto o detalhe carrega (specs/022
/// R9): sem [likesCount], a linha de curtidas fica de fora até chegar. A capa
/// pede a imagem com a mesma chave de cache do cartão, então ela já aparece
/// pronta.
class NewsDetailHeader extends StatelessWidget {
  const NewsDetailHeader({
    super.key,
    required this.news,
    required this.now,
    this.likesCount,
    this.heroTag,
  });

  static const double _imageHeight = 220;

  final NewsItemEntity news;
  final DateTime now;
  final int? likesCount;

  /// Tag do `Hero` da capa, a mesma do cartão que abriu a notícia.
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final int? likes = likesCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _hero(
          context,
          NewsCover(
            imageUrl: news.imageUrl,
            themeText: [
              ...news.categories.map((c) => c.name),
              news.title,
            ].join(' '),
            height: _imageHeight,
            radius: 24,
            labels: news.categoryLabels(),
          ),
        ),
        const SizedBox(height: AppSpacing.s5),
        Semantics(
          header: true,
          label: news.headerLabel(now),
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
              const SizedBox(height: AppSpacing.s2),
              Text(
                '${news.source} · ${news.relativeDate(now)}',
                style: AppTypography.caption.copyWith(
                  fontSize: 16,
                  color: colors.textMutedForeground,
                ),
              ),
            ],
          ),
        ),
        if (likes != null) ...[
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
                  AppStrings.newsDetailLikes.tr(
                    args: [formatLikesCount(likes)],
                  ),
                  style: AppTypography.caption.copyWith(
                    fontSize: 16,
                    color: colors.textMutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// A capa voa do cartão só com imagem e com movimento normal (specs/022
  /// FR-010), como no [NewsCard].
  Widget _hero(BuildContext context, Widget child) {
    final String? tag = heroTag;
    return tag == null || news.imageUrl == null || AppMotion.of(context).reduced
        ? child
        : Hero(tag: tag, child: child);
  }
}
