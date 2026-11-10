import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_presentation_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_cover.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Cartão de notícia do redesign 2.0 (FR-015): capa com o selo da categoria
/// e, abaixo, título e fonte. Compacto (grade) ou completo (destaques).
class NewsCard extends StatefulWidget {
  const NewsCard({
    super.key,
    required this.item,
    required this.now,
    required this.onTap,
    this.compact = true,
    this.coverHeight,
  });

  final NewsItemEntity item;
  final DateTime now;

  /// Abre a notícia; toques novos são ignorados até o futuro terminar.
  final Future<void> Function() onTap;
  final bool compact;

  /// Altura da capa na grade de 2 colunas (alturas variadas, FR-025).
  final double? coverHeight;

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  bool _opening = false;
  bool _pressed = false;

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
    final AppPalette colors = context.colors;
    final List<String> labels = item.categoryLabels();
    final bool reduceMotion = context.reduceMotion;
    // Redesign 2.0 (estilo Pinterest): a capa é o cartão; título e fonte
    // ficam logo abaixo, sem caixa em volta.
    return Semantics(
      button: true,
      label: item.semanticLabel(widget.now),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: _open,
        child: AnimatedScale(
          scale: _pressed && !reduceMotion ? 0.98 : 1,
          duration: AppMotion.duration(AppMotion.fast, reduce: reduceMotion),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              NewsCover(
                imageUrl: item.imageUrl,
                themeText: item.categories.isEmpty
                    ? item.title
                    : '${item.categories.first.name} ${item.title}',
                height: widget.coverHeight ?? (widget.compact ? 150 : 190),
                radius: widget.compact ? 20 : 24,
                labels: labels,
                trailing: _signals(item, colors),
              ),
              const SizedBox(height: AppSpacing.s3),
              Text(
                item.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style:
                    (widget.compact
                            ? AppTypography.label.copyWith(fontSize: 17)
                            : AppTypography.title3.copyWith(
                                fontWeight: FontWeight.w700,
                              ))
                        .copyWith(color: colors.textForeground, height: 1.3),
              ),
              const SizedBox(height: AppSpacing.s1),
              Text(
                '${item.source} · ${item.relativeDate(widget.now)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: colors.textMutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Lida e salva, em círculos brancos sobre a capa.
  Widget? _signals(NewsItemEntity item, AppPalette colors) {
    final List<(IconData, String, Color)> signals = [
      if (item.interaction.isRead)
        (LucideIcons.circleCheck, AppStrings.newsCardRead.tr(), colors.success),
      if (item.interaction.isSaved)
        (
          LucideIcons.bookmarkCheck,
          AppStrings.newsCardSaved.tr(),
          colors.textForeground,
        ),
    ];
    if (signals.isEmpty) return null;
    return Column(
      children: [
        for (final (icon, message, color) in signals)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Tooltip(
              message: message,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.card,
                  shape: BoxShape.circle,
                  boxShadow: colors.shadow,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            ),
          ),
      ],
    );
  }
}
