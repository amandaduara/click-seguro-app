import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_presentation_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Cartão de notícia do design system §7.8: compacto (listas) ou completo
/// (destaques). Curtir e salvar ficam para A4/A5; aqui só os sinais.
class NewsCard extends StatefulWidget {
  const NewsCard({
    super.key,
    required this.item,
    required this.now,
    required this.onTap,
    this.compact = true,
  });

  /// Quadro neutro no lugar da imagem (sem imagem ou falha ao carregar).
  static const Key imagePlaceholderKey = Key('news_card_image_placeholder');

  final NewsItemEntity item;
  final DateTime now;

  /// Abre a notícia; toques novos são ignorados até o futuro terminar.
  final Future<void> Function() onTap;
  final bool compact;

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
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
    final item = widget.item;
    return Semantics(
      button: true,
      label: item.semanticLabel(widget.now),
      excludeSemantics: true,
      child: Material(
        color: AppColors.card,
        borderRadius: AppSpacing.radius3xl,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _open,
          child: Ink(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: AppSpacing.radius3xl,
              boxShadow: AppColors.shadowSm,
            ),
            child: widget.compact ? _compact(item) : _full(item),
          ),
        ),
      ),
    );
  }

  Widget _compact(NewsItemEntity item) => Padding(
    padding: const EdgeInsets.all(AppSpacing.s3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _NewsImage(url: item.imageUrl, width: 80, height: 80),
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(child: _details(item)),
      ],
    ),
  );

  Widget _full(NewsItemEntity item) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _NewsImage(url: item.imageUrl, height: 176),
      Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: _details(item),
      ),
    ],
  );

  Widget _details(NewsItemEntity item) {
    final textTheme = Theme.of(context).textTheme;
    final labels = item.categoryLabels();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labels.isNotEmpty) ...[
          Wrap(
            spacing: AppSpacing.s1,
            runSpacing: AppSpacing.s1,
            children: [for (final label in labels) _CategoryChip(label)],
          ),
          const SizedBox(height: AppSpacing.s2),
        ],
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s2),
        Row(
          children: [
            Expanded(
              child: Text(
                '${item.source} · ${item.relativeDate(widget.now)}',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textMutedForeground,
                ),
              ),
            ),
            if (item.interaction.isRead)
              Tooltip(
                message: AppStrings.newsCardRead.tr(),
                child: const Icon(
                  LucideIcons.circleCheck,
                  size: 16,
                  color: AppColors.success,
                ),
              ),
            if (item.interaction.isSaved) ...[
              const SizedBox(width: AppSpacing.s1),
              Tooltip(
                message: AppStrings.newsCardSaved.tr(),
                child: const Icon(
                  LucideIcons.bookmarkCheck,
                  size: 16,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: AppSpacing.radiusFull,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Imagem da notícia, com quadro neutro sem imagem ou se falhar (R8).
class _NewsImage extends StatelessWidget {
  const _NewsImage({required this.url, required this.height, this.width});

  final String? url;
  final double height;
  final double? width;

  Widget _placeholder() => Container(
    key: NewsCard.imagePlaceholderKey,
    width: width,
    height: height,
    color: AppColors.input,
    alignment: Alignment.center,
    child: const Icon(
      LucideIcons.newspaper,
      color: AppColors.textMutedForeground,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final String? source = url;
    if (source == null) return _placeholder();
    return Image.network(
      source,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(),
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : _placeholder(),
    );
  }
}
