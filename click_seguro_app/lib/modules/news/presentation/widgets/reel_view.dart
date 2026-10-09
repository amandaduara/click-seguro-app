import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reel_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_presentation_extension.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/reel_presentation_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Um Reel em tela cheia (design system §7.10): imagem ao fundo com
/// gradiente, categorias, título, trecho, fonte e data, "Ler notícia
/// completa" e, à direita, as [actions].
class ReelView extends StatelessWidget {
  const ReelView({
    super.key,
    required this.reel,
    required this.now,
    required this.actions,
    required this.onReadFull,
    this.footer,
  });

  static const double _actionsWidth = 64;

  final ReelEntity reel;
  final DateTime now;
  final Widget actions;
  final VoidCallback onReadFull;

  /// Aviso no último Reel: fim da lista ou falha ao carregar mais.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final String? image = reel.news.imageUrl;
    final List<String> categories = reel.news.categoryLabels();
    const Color onDark = AppColors.textPrimaryForeground;
    final Widget? footer = this.footer;

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image == null)
            const _NoImage()
          else
            Opacity(
              opacity: 0.7,
              child: Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _NoImage(),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Color(0x1A000000), Colors.black],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s5,
                AppSpacing.s5,
                AppSpacing.s2,
                AppSpacing.s5,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          label: reel.semanticLabel(now),
                          excludeSemantics: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (categories.isNotEmpty) ...[
                                Wrap(
                                  spacing: AppSpacing.s1,
                                  runSpacing: AppSpacing.s1,
                                  children: [
                                    for (final label in categories)
                                      _CategoryChip(label: label),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.s3),
                              ],
                              Text(
                                reel.news.title,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: onDark,
                                ),
                              ),
                              if (reel.content.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.s2),
                                Text(
                                  reel.content,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    color: onDark.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.s2),
                              Text(
                                '${reel.news.source} · '
                                '${reel.news.relativeDate(now)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: onDark.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: FilledButton(
                            onPressed: onReadFull,
                            style: FilledButton.styleFrom(
                              backgroundColor: onDark,
                              foregroundColor: AppColors.secondary,
                              minimumSize: const Size(48, 48),
                              shape: const StadiumBorder(),
                              textStyle: textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: Text(AppStrings.newsReelsReadFull.tr()),
                          ),
                        ),
                        if (footer != null) ...[
                          const SizedBox(height: AppSpacing.s3),
                          footer,
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: _actionsWidth, child: actions),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fundo neutro para Reel sem imagem ou com imagem que não carrega.
class _NoImage extends StatelessWidget {
  const _NoImage();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.secondary,
    child: Center(
      child: Icon(LucideIcons.newspaper, size: 64, color: Color(0x4DFFFFFF)),
    ),
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: const BoxDecoration(
      color: Color(0x33FFFFFF),
      borderRadius: AppSpacing.radiusFull,
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryForeground,
      ),
    ),
  );
}
