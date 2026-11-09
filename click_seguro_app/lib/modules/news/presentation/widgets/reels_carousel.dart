import 'dart:async';

import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_network_image.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/reel_view.dart';
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

class _ReelCard extends StatefulWidget {
  const _ReelCard({
    required this.item,
    required this.width,
    required this.onTap,
  });

  final NewsItemEntity item;
  final double width;
  final VoidCallback onTap;

  @override
  State<_ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends State<_ReelCard> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  /// A aba de Reels tem outro `Navigator`, então não há `Hero`: a imagem em
  /// tela cheia vai para o cache quando o cartão aparece, e o Reel já a
  /// encontra ao chegar (specs/022 R10). Só no toque não dava tempo de
  /// baixá-la (achado da T058).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(ReelView.precache(context, widget.item.imageUrl));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final NewsItemEntity item = widget.item;
    final String? image = item.imageUrl;
    return Semantics(
      button: true,
      label: '${AppStrings.newsReelsBadge.tr()}: ${item.title}, ${item.source}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: AppMotion.of(context).short,
          curve: AppMotion.standard,
          child: Container(
            width: widget.width,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.colors.secondary,
              borderRadius: AppSpacing.radius3xl,
              boxShadow: context.colors.shadowMd,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                SafeNetworkImage(
                  url: image,
                  width: widget.width,
                  height: widget.width * 16 / 9,
                  placeholder: const SizedBox.shrink(),
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
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      borderRadius: AppSpacing.radiusFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.sparkles,
                          size: 10,
                          color: context.colors.textPrimaryForeground,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.newsReelsBadge.tr().toUpperCase(),
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: context.colors.textPrimaryForeground,
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
                          color: context.colors.textPrimaryForeground,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s1),
                      Text(
                        item.source,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: context.colors.textPrimaryForeground
                              .withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
