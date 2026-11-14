import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_icon_button.dart';
import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:click_seguro_app/core/widgets/safe_state_switcher.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_cover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Capa do detalhe (redesign 2.0, Figma quadro 05, T055): imagem de 270 até
/// a borda, sem título, com o "Voltar" redondo à esquerda e [actions]
/// (curtir, compartilhar e salvar) à direita. A folha branca do texto começa
/// sobre a capa, com o canto de 28.
///
/// Fixa ao rolar: a capa some e os botões continuam no topo, numa faixa
/// branca, para o texto nunca ficar por baixo deles.
///
/// A capa pede a imagem com a mesma chave de cache do cartão (decodifica pela
/// largura da tela), então ela já aparece pronta. Sem [news]: com [loading],
/// o esqueleto no lugar da imagem (a capa só aparece com o detalhe
/// carregado); sem ele (erro), só o fundo.
class NewsDetailCoverBar extends StatelessWidget {
  const NewsDetailCoverBar({
    super.key,
    this.news,
    this.heroTag,
    this.actions,
    this.loading = false,
  });

  static const double coverHeight = 270;
  static const double sheetRadius = 28;
  static const Key backKey = ValueKey('detail-back');

  final NewsItemEntity? news;

  /// Tag do `Hero` da capa, a mesma do cartão que abriu a notícia.
  final String? heroTag;

  /// Botões da direita; `null` até o detalhe chegar.
  final Widget? actions;

  /// Carregando: esqueleto no lugar da capa.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final double top = MediaQuery.paddingOf(context).top;
    final Widget? trailing = actions;
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      // 48 do botão e um respiro em cima e embaixo.
      toolbarHeight: 48 + AppSpacing.s4,
      expandedHeight: coverHeight,
      leadingWidth: 48 + AppSpacing.s5,
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.s5),
        child: Center(
          child: SafeIconButton(
            key: backKey,
            onImage: true,
            icon: LucideIcons.chevronLeft,
            semanticLabel: AppStrings.newsDetailBack.tr(),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      ),
      actions: [
        ?trailing,
        const SizedBox(width: AppSpacing.s5),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: SafeStateSwitcher(
          stateKey: news != null,
          // A troca empilha sem esticar: o tamanho da capa vem daqui.
          child: SizedBox.expand(
            child: _cover(context, colors, coverHeight + top),
          ),
        ),
      ),
      // O começo da folha branca, por cima da base da capa.
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(sheetRadius),
        child: Container(
          height: sheetRadius,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(sheetRadius),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cover(BuildContext context, AppPalette colors, double height) {
    final NewsItemEntity? item = news;
    if (item == null) {
      if (!loading) return ColoredBox(color: colors.surface);
      // O esqueleto do corpo já diz "Carregando": este não repete.
      return ExcludeSemantics(
        child: SafeSkeleton(
          enabled: true,
          child: SafeSkeleton.leaf(
            Container(height: height, color: colors.surface),
          ),
        ),
      );
    }
    final Widget cover = NewsCover(
      imageUrl: item.imageUrl,
      themeText: [...item.categories.map((c) => c.name), item.title].join(' '),
      height: height,
      radius: 0,
    );
    // A capa voa do cartão só com imagem e com movimento normal (specs/022
    // FR-010), como no `NewsCard`.
    final String? tag = heroTag;
    return tag == null || item.imageUrl == null || AppMotion.of(context).reduced
        ? cover
        : Hero(tag: tag, child: cover);
  }
}
