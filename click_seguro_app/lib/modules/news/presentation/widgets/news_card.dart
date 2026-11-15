import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_presentation_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/press_scale.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_cover.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Cartão de notícia do redesign 2.0 (FR-015): caixa com borda, capa com o
/// selo da categoria e, abaixo, título e fonte. Compacto (grade) ou completo (destaques).
class NewsCard extends StatefulWidget {
  const NewsCard({
    super.key,
    required this.item,
    required this.now,
    required this.onTap,
    this.compact = true,
    this.coverHeight,
    this.heroTag,
    this.showSignals = true,
  });

  final NewsItemEntity item;
  final DateTime now;

  /// Abre a notícia; toques novos são ignorados até o futuro terminar.
  final Future<void> Function() onTap;
  final bool compact;

  /// Altura da capa na grade de 2 colunas (alturas variadas, FR-025).
  final double? coverHeight;

  /// Tag do `Hero` da capa, a mesma passada na prévia do detalhe.
  final String? heroTag;

  /// Sinais de "lida" e "salva" na capa. Falso nas listas do perfil (lidas,
  /// salvas e curtidas), onde o próprio título da lista já diz isso.
  final bool showSignals;

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
    final AppPalette colors = context.colors;
    final List<String> labels = item.categoryLabels();
    final double inset = widget.compact ? AppSpacing.s3 : AppSpacing.s4;
    // Cartão padrão do redesign (SafeCard): caixa branca com borda; a capa
    // ocupa o topo e o título e a fonte ficam dentro, abaixo dela.
    return Semantics(
      button: true,
      label: item.semanticLabel(widget.now),
      excludeSemantics: true,
      child: PressScale(
        enabled: true,
        pressedScale: 0.98,
        onTap: _open,
        child: Container(
          decoration: SafeCard.decoration(colors),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _hero(
                NewsCover(
                  imageUrl: item.imageUrl,
                  themeText: item.categories.isEmpty
                      ? item.title
                      : '${item.categories.first.name} ${item.title}',
                  height: widget.coverHeight ?? (widget.compact ? 150 : 190),
                  // O canto vem do cartão.
                  radius: 0,
                  labels: labels,
                  trailing: widget.showSignals ? _signals(item, colors) : null,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(inset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (widget.compact
                                  ? AppTypography.label
                                  : AppTypography.title3.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ))
                              .copyWith(
                                color: colors.textForeground,
                                height: 1.3,
                              ),
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
            ],
          ),
        ),
      ),
    );
  }

  /// Só com imagem (sem ela o detalhe não tem para onde voar) e com
  /// movimento normal (specs/022 FR-010).
  Widget _hero(Widget child) {
    final String? tag = widget.heroTag;
    if (tag == null ||
        widget.item.imageUrl == null ||
        AppMotion.of(context).reduced) {
      return child;
    }
    return Hero(tag: tag, child: child);
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
