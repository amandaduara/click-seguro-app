import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_network_image.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_presentation_extension.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Cabeçalho do detalhe: imagem (se houver), categorias, título, "fonte ·
/// data" e curtidas (FR-001). O leitor de tela lê título, fonte e data.
///
/// Também mostra a prévia do cartão enquanto o detalhe carrega (specs/022
/// R9): sem [likesCount], a linha de curtidas fica de fora até chegar.
class NewsDetailHeader extends StatelessWidget {
  const NewsDetailHeader({
    super.key,
    required this.news,
    required this.now,
    this.likesCount,
    this.heroTag,
  });

  static const double _imageHeight = 200;

  final NewsItemEntity news;
  final DateTime now;
  final int? likesCount;

  /// Tag do `Hero` da imagem, a mesma do cartão que abriu a notícia.
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final String? image = news.imageUrl;
    final List<String> categories = news.categoryLabels();
    final int? likes = likesCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (image != null) ...[
          _hero(
            context,
            ClipRRect(
              borderRadius: AppSpacing.radius3xl,
              child: SafeNetworkImage(
                url: image,
                height: _imageHeight,
                width: double.infinity,
                // Vindo de um cartão, a miniatura dele já está no cache.
                placeholder: heroTag == null
                    ? const _ImagePlaceholder()
                    : _CardThumbnail(url: image),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
        ],
        if (categories.isNotEmpty) ...[
          Wrap(
            spacing: AppSpacing.s1,
            runSpacing: AppSpacing.s1,
            children: [for (final label in categories) _CategoryChip(label)],
          ),
          const SizedBox(height: AppSpacing.s3),
        ],
        Semantics(
          header: true,
          label: news.headerLabel(now),
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                news.title,
                style: textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: context.colors.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                '${news.source} · ${news.relativeDate(now)}',
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  color: context.colors.textMutedForeground,
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
                color: context.colors.textMutedForeground,
              ),
              const SizedBox(width: AppSpacing.s2),
              Flexible(
                child: Text(
                  AppStrings.newsDetailLikes.tr(
                    args: [formatLikesCount(likes)],
                  ),
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: context.colors.textMutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// A imagem voa do cartão só com movimento normal (specs/022 FR-010).
  Widget _hero(BuildContext context, Widget child) {
    final String? tag = heroTag;
    return tag == null || AppMotion.of(context).reduced
        ? child
        : Hero(tag: tag, child: child);
  }
}

/// A miniatura do cartão compacto, ampliada, enquanto a imagem grande
/// carrega (specs/022 FR-017: o detalhe mostra na hora a imagem que o
/// cartão já tinha). Sem ela, o quadro neutro.
class _CardThumbnail extends StatelessWidget {
  const _CardThumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const _ImagePlaceholder(),
      Positioned.fill(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SafeNetworkImage(
            url: url,
            width: NewsCard.compactImageSize,
            height: NewsCard.compactImageSize,
            placeholder: const SizedBox.square(
              dimension: NewsCard.compactImageSize,
            ),
          ),
        ),
      ),
    ],
  );
}

/// Quadro neutro do feed para imagem que ainda carrega ou que falhou.
class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    height: NewsDetailHeader._imageHeight,
    width: double.infinity,
    color: context.colors.input,
    alignment: Alignment.center,
    child: Icon(
      LucideIcons.newspaper,
      size: 40,
      color: context.colors.textMutedForeground,
    ),
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.1),
        borderRadius: AppSpacing.radiusFull,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: context.colors.primary,
        ),
      ),
    );
  }
}
