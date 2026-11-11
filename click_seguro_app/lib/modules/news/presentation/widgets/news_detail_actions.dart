import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/safe_icon_button.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_presentation_extension.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/reel_presentation_extension.dart';
import 'package:click_seguro_app/modules/news/presentation/routes/news_detail_preview.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_action_hero.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Curtir, compartilhar e salvar da notícia aberta (RF-016, RF-019;
/// redesign 2.0, Figma quadro 05): botões brancos sobre a capa, à direita.
///
/// Com [heroTags] (aberto por um Reel), cada botão é o destino do `Hero` do
/// mesmo botão no Reel.
class NewsDetailActions extends StatelessWidget {
  const NewsDetailActions({
    super.key,
    required this.isLiked,
    required this.likesCount,
    required this.onLike,
    required this.isSaved,
    required this.onSave,
    required this.onShare,
    this.heroTags,
  });

  static const Key likeKey = ValueKey('detail-like');
  static const Key saveKey = ValueKey('detail-save');
  static const Key shareKey = ValueKey('detail-share');

  /// Estados já resolvidos pela página: o visitante vê sempre `false`.
  final bool isLiked;
  final int likesCount;
  final VoidCallback onLike;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final NewsActionTags? heroTags;

  @override
  Widget build(BuildContext context) {
    final NewsActionTags? tags = heroTags;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NewsActionHero(
          tag: tags?.like,
          child: _LikeButton(
            key: likeKey,
            isLiked: isLiked,
            likesCount: likesCount,
            onPressed: onLike,
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        NewsActionHero(
          tag: tags?.share,
          child: SafeIconButton(
            key: shareKey,
            onImage: true,
            icon: LucideIcons.share2,
            semanticLabel: AppStrings.newsDetailShare.tr(),
            onPressed: onShare,
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        NewsActionHero(
          tag: tags?.save,
          // O "selecionado" junta-se ao botão (sem `container`): o leitor de
          // tela diz "Salvo, selecionado".
          child: Semantics(
            selected: isSaved,
            child: SafeIconButton(
              key: saveKey,
              onImage: true,
              icon: isSaved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
              semanticLabel: saveSemanticLabel(isSaved: isSaved),
              onPressed: onSave,
            ),
          ),
        ),
      ],
    );
  }
}

/// Pílula branca de 48 com o coração e a contagem, no visual do
/// `SafeIconButton` sobre imagem. Curtido: coração cheio coral. Lido como
/// "Curtir, 3 curtidas" / "Curtido, 4 curtidas, selecionado".
class _LikeButton extends StatelessWidget {
  const _LikeButton({
    super.key,
    required this.isLiked,
    required this.likesCount,
    required this.onPressed,
  });

  final bool isLiked;
  final int likesCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final String likes = formatLikesCount(likesCount);
    return Semantics(
      button: true,
      selected: isLiked,
      label: (isLiked ? AppStrings.newsReelsLiked : AppStrings.newsReelsLike)
          .tr(args: [likes]),
      onTap: onPressed,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: AppSpacing.radiusFull,
            boxShadow: colors.shadow,
            border: colors.shadow.isEmpty
                ? Border.all(color: colors.border)
                : null,
          ),
          child: InkWell(
            borderRadius: AppSpacing.radiusFull,
            onTap: onPressed,
            child: ConstrainedBox(
              // 48: alvo de toque mínimo (RNF-003).
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : LucideIcons.heart,
                      size: 24,
                      color: isLiked ? colors.primary : colors.textForeground,
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    Text(
                      likes,
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
