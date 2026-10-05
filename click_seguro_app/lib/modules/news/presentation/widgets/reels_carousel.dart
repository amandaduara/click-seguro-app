import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Carrossel "Novidades" com cartões verticais de Reels (design system
/// §7.9). Tocar abre a aba de Reels naquela notícia.
class ReelsCarousel extends StatelessWidget {
  const ReelsCarousel({super.key, required this.reels, required this.onOpen});

  static const double _cardWidth = 160;

  final List<NewsItemEntity> reels;
  final ValueChanged<NewsItemEntity> onOpen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cardWidth * 16 / 9,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
        itemCount: reels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) => _ReelCard(
          item: reels[index],
          width: _cardWidth,
          onTap: () => onOpen(reels[index]),
        ),
      ),
    );
  }
}

class _ReelCard extends StatelessWidget {
  const _ReelCard({
    required this.item,
    required this.width,
    required this.onTap,
  });

  final NewsItemEntity item;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final String? image = item.imageUrl;
    return Semantics(
      button: true,
      label: '${AppStrings.newsReelsBadge.tr()}: ${item.title}, ${item.source}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: AppSpacing.radius3xl,
            boxShadow: AppColors.shadowMd,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (image != null)
                Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xE6000000),
                      Color(0x66000000),
                      Color(0x1A000000),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.s3,
                left: AppSpacing.s3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppSpacing.radiusFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.sparkles,
                        size: 10,
                        color: AppColors.textPrimaryForeground,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppStrings.newsReelsBadge.tr().toUpperCase(),
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: AppSpacing.s4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryForeground,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      item.source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimaryForeground.withValues(
                          alpha: 0.75,
                        ),
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
