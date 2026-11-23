import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_empty_state.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_icon_button.dart';
import 'package:click_seguro_app/core/widgets/safe_offline_banner.dart';
import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:click_seguro_app/core/widgets/safe_state_switcher.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/common/services/external_launcher_service.dart';
import 'package:click_seguro_app/modules/common/services/share_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_detail_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/news_detail_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/news_detail_status.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_detail_presentation_extension.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_placeholders.dart';
import 'package:click_seguro_app/modules/news/presentation/routes/news_detail_preview.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_detail_actions.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_detail_cover_bar.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_detail_header.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/read_aloud_bar.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/related_activity_card.dart';
import 'package:click_seguro_app/modules/shell/shell.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Detalhe da notícia (RF-014, RF-015, RF-019, specs/010-detalhe-noticia):
/// notícia completa, "Ouvir", "Salvar", "Compartilhar", "Abrir fonte",
/// curtir e a atividade relacionada. O [NewsDetailController] vem da rota
/// (um por abertura).
///
/// Redesign 2.0 (Figma quadro 05): capa até a borda com curtir,
/// compartilhar e salvar sobre ela e a folha branca com o texto; a atividade
/// relacionada fica no fim do texto.
///
/// Enquanto carrega, a capa e o conteúdo são esqueleto, com ou sem
/// [preview]: a imagem só aparece com o detalhe carregado (e voa de volta ao
/// cartão pelo `Hero` ao voltar). Aberto por um Reel, a prévia traz curtir e
/// salvar, e os botões voam da coluna do Reel para o topo
/// ([NewsActionsPreview]), desativados até a carga. Com erro, a prévia dá o
/// título acima do erro.
class NewsDetailPage extends StatefulWidget {
  const NewsDetailPage({super.key, required this.newsId, this.preview});

  static const Key sourceKey = ValueKey('detail-source');

  final String newsId;
  final NewsDetailPreview? preview;

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  late final NewsDetailController _controller;
  late final ReadAloudController _readAloud;
  StreamSubscription<NewsDetailMessage>? _messages;
  Locale? _locale;
  bool _isSharing = false;
  bool _isOpeningSource = false;
  bool _isOpeningPractice = false;

  @override
  void initState() {
    super.initState();
    _controller = context.read<NewsDetailController>();
    _readAloud = GetIt.instance<ReadAloudController>();
    _controller.addListener(_maybeAutoRead);
    _readAloud.addListener(_maybeAutoRead);
    _messages = _controller.messages.listen(_showMessage);
  }

  /// O idioma da voz é o do app: prepara de novo se ele mudar.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Locale locale = context.locale;
    if (locale == _locale) return;
    _locale = locale;
    unawaited(_readAloud.prepare(locale));
  }

  @override
  void dispose() {
    _controller.removeListener(_maybeAutoRead);
    _readAloud.removeListener(_maybeAutoRead);
    unawaited(_messages?.cancel());
    _readAloud.dispose();
    super.dispose();
  }

  /// Leitura automática (RF-040): quando a carga e o preparo da voz
  /// terminam, uma vez por abertura. Marca como feita ao começar.
  void _maybeAutoRead() {
    final NewsDetailEntity? detail = _controller.detail;
    if (!mounted ||
        _controller.status != NewsDetailStatus.loaded ||
        detail == null ||
        _controller.autoReadDone ||
        !_readAloud.isContentAvailable ||
        !GetIt.instance<AccessibilityPreferencesNotifier>()
            .value
            .autoReadAloud) {
      return;
    }
    _controller.markAutoReadDone();
    unawaited(_readAloud.speak(detail.spokenText, content: true));
  }

  /// "Notícia salva", "Removida dos salvos" ou o erro. "Não encontrada" já
  /// aparece na própria tela.
  void _showMessage(NewsDetailMessage message) {
    if (!mounted) return;
    final String? text = switch (message.type) {
      NewsDetailMessageType.saved => AppStrings.newsReelsSavedToast.tr(),
      NewsDetailMessageType.removed => AppStrings.newsReelsRemovedToast.tr(),
      NewsDetailMessageType.saveFailed || NewsDetailMessageType.likeFailed =>
        (message.failureKey ?? AppStrings.errorGeneric).tr(),
      NewsDetailMessageType.notFound => null,
    };
    if (text == null) return;
    _snack(text);
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Menu do aparelho; cancelar ou falhar não mostra aviso (FR-019). Sem
  /// conta também vale (RN-003).
  Future<void> _share(NewsDetailEntity detail) async {
    if (_isSharing) return;
    _isSharing = true;
    try {
      await GetIt.instance<ShareService>().shareText(
        detail.shareText,
        subject: detail.news.title,
      );
    } finally {
      _isSharing = false;
    }
  }

  /// Navegador externo; se o aparelho não abrir, avisa (FR-020).
  Future<void> _openSource(NewsDetailEntity detail) async {
    if (_isOpeningSource) return;
    _isOpeningSource = true;
    try {
      final bool opened = await GetIt.instance<ExternalLauncherService>()
          .openUrl(detail.news.sourceUrl);
      if (!opened && mounted) _snack(AppStrings.newsReelsOpenSourceFailed.tr());
    } finally {
      _isOpeningSource = false;
    }
  }

  /// Visitante vê o convite e nenhum pedido sai (RN-003).
  Future<void> _save() async {
    if (await requireAccount(context)) unawaited(_controller.toggleSave());
  }

  /// Visitante vê o convite e nenhum pedido sai (RN-003).
  Future<void> _like() async {
    if (await requireAccount(context)) unawaited(_controller.toggleLike());
  }

  /// Abre o módulo sugerido; toques novos são ignorados até voltar.
  Future<void> _openPractice(SuggestedModuleEntity module) async {
    if (_isOpeningPractice) return;
    _isOpeningPractice = true;
    try {
      // Por caminho, sem importar `activities` (constituição I).
      await context.push<void>('/activities/${module.id}');
    } finally {
      _isOpeningPractice = false;
    }
  }

  void _toggleListen(NewsDetailEntity detail) {
    if (_readAloud.isSpeaking) {
      _controller.markAutoReadDone();
      unawaited(_readAloud.stop());
    } else {
      unawaited(_readAloud.speak(detail.spokenText, content: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final NewsDetailController controller = context
        .watch<NewsDetailController>();
    final NewsDetailEntity? detail =
        controller.status == NewsDetailStatus.loaded ? controller.detail : null;
    // Com curtir ou salvar em andamento, não sai (nem pelo voltar do
    // aparelho): as listas de lidas, salvas e curtidas só ficam certas com o
    // pedido terminado. Tentar sair mostra o aviso.
    final bool busy = controller.isSaving || controller.isLiking;
    return PopScope(
      canPop: !busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _warnPending();
      },
      child: Scaffold(
        backgroundColor: context.colors.card,
        body: _content(controller, detail, busy: busy),
      ),
    );
  }

  /// "Aguarde: salvando sua escolha." ao tentar sair durante um pedido.
  void _warnPending() => _snack(AppStrings.newsDetailWaitPending.tr());

  Widget _content(
    NewsDetailController controller,
    NewsDetailEntity? detail, {
    required bool busy,
  }) {
    if (controller.status == NewsDetailStatus.notFound) {
      return const _WithBackButton(child: _NotFound());
    }
    final NewsItemEntity? previewItem = widget.preview?.item;
    final bool failed = controller.status == NewsDetailStatus.error;
    // Erro sem prévia: sem cabeçalho para mostrar, só o "Voltar" e o erro.
    // No resto, a capa fica parada (os `Hero` dos botões e da capa nunca
    // aparecem duas vezes) e só o que está abaixo dela troca.
    final bool bareError = failed && previewItem == null;
    return SafeStateSwitcher(
      stateKey: bareError,
      child: bareError
          ? _WithBackButton(child: _error(controller))
          : _page(
              controller,
              detail,
              previewItem,
              loading: detail == null && !failed,
              busy: busy,
            ),
    );
  }

  Widget _error(NewsDetailController controller) {
    final Failure? failure = controller.failure;
    return SafeErrorState(failure: failure, onRetry: controller.retry);
  }

  /// Capa e, abaixo, o cabeçalho e o corpo; o esqueleto de tudo enquanto
  /// carrega (a imagem só aparece com o detalhe, mesmo com a prévia); ou,
  /// com a prévia, o título dela e o erro.
  Widget _page(
    NewsDetailController controller,
    NewsDetailEntity? detail,
    NewsItemEntity? previewItem, {
    required bool loading,
    required bool busy,
  }) {
    // Respiro no fim acima da barra de navegação do aparelho (área segura).
    final double bottom = MediaQuery.paddingOf(context).bottom + AppSpacing.s6;
    return CustomScrollView(
      physics: loading ? const NeverScrollableScrollPhysics() : null,
      slivers: [
        NewsDetailCoverBar(
          news: detail?.news,
          heroTag: widget.preview?.heroTag,
          actions: _actions(controller, detail),
          loading: loading,
          onBlockedBack: busy ? _warnPending : null,
        ),
        if (detail != null && controller.isFromCache)
          const SliverToBoxAdapter(child: SafeOfflineBanner()),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(AppSpacing.s5, 0, AppSpacing.s5, bottom),
          sliver: SliverToBoxAdapter(
            child: SafeStateSwitcher(
              stateKey: controller.status,
              child: switch (detail) {
                final NewsDetailEntity detail => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NewsDetailHeader(
                      news: detail.news,
                      now: DateTime.now(),
                      readingMinutes: detail.readingMinutes,
                    ),
                    _body(detail),
                  ],
                ),
                null when !loading && previewItem != null => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NewsDetailHeader(news: previewItem, now: DateTime.now()),
                    _error(controller),
                  ],
                ),
                null => SafeSkeleton(
                  enabled: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      NewsDetailHeader(
                        news: NewsPlaceholders.item(0),
                        now: DateTime.now(),
                      ),
                      const _BodyPlaceholder(),
                    ],
                  ),
                ),
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Curtir, compartilhar e salvar, sobre a capa. Antes da carga, só com a
  /// prévia de um Reel: o estado que ele mostrava, desativados, para os
  /// botões já estarem no lugar quando voam ([NewsActionsPreview]). Com um
  /// pedido em andamento, o botão mostra o carregando.
  Widget? _actions(NewsDetailController controller, NewsDetailEntity? detail) {
    final NewsActionsPreview? preview = widget.preview?.actions;
    if (detail == null && preview == null) return null;
    return ValueListenableBuilder<UserSessionStatus>(
      valueListenable: GetIt.instance<UserSessionService>().sessionStatus,
      // O visitante vê sempre o coração e o marcador vazios (FR-012).
      builder: (context, status, _) {
        final bool signedIn = status == UserSessionStatus.authenticated;
        return NewsDetailActions(
          heroTags: widget.preview?.actionTags,
          isLiked: signedIn && (detail?.isLiked ?? preview!.isLiked),
          likesCount: detail?.likesCount ?? preview!.likesCount,
          isSaved: signedIn && (detail?.isSaved ?? preview!.isSaved),
          isLiking: controller.isLiking,
          isSaving: controller.isSaving,
          onLike: detail == null ? null : () => unawaited(_like()),
          onSave: detail == null ? null : () => unawaited(_save()),
          onShare: detail == null ? null : () => unawaited(_share(detail)),
        );
      },
    );
  }

  /// O que vem abaixo do cabeçalho: abrir a fonte, ouvir, texto e atividade.
  Widget _body(NewsDetailEntity detail) {
    final AppPalette colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (detail.hasSource) ...[
          const SizedBox(height: AppSpacing.s2),
          Align(
            alignment: AlignmentDirectional.centerStart,
            // O SafeButton já é lido como botão, com o rótulo e o toque.
            child: SafeButton(
              key: NewsDetailPage.sourceKey,
              label: AppStrings.newsReelsOpenSource.tr(),
              tone: SafeButtonTone.link,
              size: SafeButtonSize.compact,
              icon: const Icon(LucideIcons.externalLink),
              onPressed: () => unawaited(_openSource(detail)),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.s4),
        ListenableBuilder(
          listenable: _readAloud,
          builder: (context, _) => ReadAloudBar(
            isAvailable: _readAloud.isContentAvailable,
            isSpeaking: _readAloud.isSpeaking,
            speed: _readAloud.speed,
            onToggle: () => _toggleListen(detail),
            onSpeedChanged: _readAloud.setSpeed,
          ),
        ),
        const SizedBox(height: AppSpacing.s5),
        Text(
          detail.hasContent
              ? detail.content.trim()
              : AppStrings.newsDetailNoContent.tr(),
          style: AppTypography.bodyLarge.copyWith(
            color: detail.hasContent
                ? colors.textForeground
                : colors.textMutedForeground,
          ),
        ),
        if (detail.suggestedModule case final module?) ...[
          const SizedBox(height: AppSpacing.s6),
          RelatedActivityCard(
            module: module,
            onTap: () => _openPractice(module),
          ),
        ],
      ],
    );
  }
}

/// Corpo em esqueleto: o cartão de ouvir e algumas linhas de texto.
class _BodyPlaceholder extends StatelessWidget {
  const _BodyPlaceholder();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: AppSpacing.s5),
      SafeSkeleton.leaf(
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: AppSpacing.radiusLg,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.s5),
      Text(
        SafeSkeleton.text(60),
        style: AppTypography.bodyLarge.copyWith(
          color: context.colors.textForeground,
        ),
      ),
    ],
  );
}

/// Erro ou "não encontrada": sem capa, só o "Voltar" redondo no topo.
class _WithBackButton extends StatelessWidget {
  const _WithBackButton({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s2,
            AppSpacing.s5,
            0,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SafeIconButton(
              key: NewsDetailCoverBar.backKey,
              icon: LucideIcons.chevronLeft,
              semanticLabel: AppStrings.newsDetailBack.tr(),
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    ),
  );
}

/// "Notícia não encontrada": sem "Tentar novamente"; o "Voltar" leva de
/// volta.
class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) =>
      SafeEmptyState(message: AppStrings.newsErrorNotFound.tr());
}
