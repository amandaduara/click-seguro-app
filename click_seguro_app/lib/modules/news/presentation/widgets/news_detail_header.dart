import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_detail_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_detail_presentation_extension.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_presentation_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Cabeçalho do detalhe: imagem (se houver), categorias, título, "fonte ·
/// data" e curtidas (FR-001). O leitor de tela lê título, fonte e data.
class NewsDetailHeader extends StatelessWidget {
  const NewsDetailHeader({super.key, required this.detail, required this.now});

  static const double _imageHeight = 200;

  final NewsDetailEntity detail;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final String? image = detail.news.imageUrl;
    final List<String> categories = detail.news.categoryLabels();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (image != null) ...[
          ClipRRect(
            borderRadius: AppSpacing.radius3xl,
            child: Image.network(
              image,
              height: _imageHeight,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (context, _, _) => const _ImagePlaceholder(),
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : const _ImagePlaceholder(),
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
          label: detail.semanticLabel(now),
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.news.title,
                style: textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: context.colors.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                '${detail.news.source} · ${detail.news.relativeDate(now)}',
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  color: context.colors.textMutedForeground,
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
              color: context.colors.textMutedForeground,
            ),
            const SizedBox(width: AppSpacing.s2),
            Flexible(
              child: Text(
                AppStrings.newsDetailLikes.tr(args: [detail.formattedLikes]),
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  color: context.colors.textMutedForeground,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
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
