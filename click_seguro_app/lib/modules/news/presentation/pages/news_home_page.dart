import 'dart:async';

import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/listen_button.dart';
import 'package:click_seguro_app/core/widgets/safe_empty_state.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_offline_banner.dart';
import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:click_seguro_app/core/widgets/safe_state_switcher.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/feed_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/feed_message.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/feed_status.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_placeholders.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_presentation_extension.dart';
import 'package:click_seguro_app/modules/news/presentation/routes/news_detail_preview.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/category_filter_bar.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/feed_list_footer.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/feed_search_field.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/feed_section_title.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_card.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/reels_carousel.dart';
import 'package:click_seguro_app/modules/shell/shell.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_grid.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Aba Início: o feed de notícias (specs/006-feed-inicio).
///
/// "Ouvir" ao lado do título "Destaques" (Figma quadro 04) lê os títulos e as
/// fontes dos destaques; some sem voz no idioma do app. A leitura para ao
/// trocar de aba, ao abrir outra tela por cima e ao fechar a página.
class NewsHomePage extends StatefulWidget {
  const NewsHomePage({super.key});

  static const Key highlightsListenKey = ValueKey('home-highlights-listen');

  @override
  State<NewsHomePage> createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  StreamSubscription<FeedMessage>? _messages;
  late final FeedController _feed;
  late final ReadAloudController _readAloud;
  Locale? _locale;
  bool? _visible;

  /// Puxar para atualizar em andamento: o indicador do gesto já basta, sem
  /// a barra de progresso (specs/022 US1).
  bool _pulling = false;

  @override
  void initState() {
    super.initState();
    // A voz antes de ouvir o feed: um aviso do feed já usa a leitura.
    _readAloud = GetIt.instance<ReadAloudController>();
    _feed = context.read<FeedController>()..addListener(_stopWithoutHighlights);
    _messages = _feed.messages.listen(_showMessage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // O idioma da voz é o do app: prepara de novo se ele mudar.
    final Locale locale = context.locale;
    if (locale != _locale) {
      _locale = locale;
      unawaited(_readAloud.prepare(locale));
    }
    // Aba escondida ou outra tela por cima: o shell e o navegador desligam
    // o `TickerMode` da página, e a leitura para.
    final bool visible = TickerMode.valuesOf(context).enabled;
    if (visible == _visible) return;
    _visible = visible;
    if (!visible) {
      // Fora do build: parar avisa os ouvintes na hora.
      WidgetsBinding.instance.addPostFrameCallback((_) => _stopReading());
    }
  }

  @override
  void dispose() {
    _feed.removeListener(_stopWithoutHighlights);
    unawaited(_messages?.cancel());
    _readAloud.dispose();
    super.dispose();
  }

  /// Só a leitura desta página: o motor é um só e a próxima tela pode já
  /// estar lendo.
  void _stopReading() {
    if (mounted && _readAloud.isSpeaking) unawaited(_readAloud.stop());
  }

  /// O botão sumiu (filtro sem destaques, erro): a leitura para com ele.
  void _stopWithoutHighlights() {
    if (_feed.status != FeedStatus.loaded || _feed.highlights.isEmpty) {
      _stopReading();
    }
  }

  void _toggleHighlights(List<NewsItemEntity> highlights) {
    if (_readAloud.isSpeaking) {
      unawaited(_readAloud.stop());
    } else {
      unawaited(
        _readAloud.speakParts(
          highlights.spokenParts(AppStrings.newsSectionHighlights.tr()),
        ),
      );
    }
  }

  /// Falha ao atualizar com a lista na tela: a lista fica e um aviso
  /// explica (FR-003).
  void _showMessage(FeedMessage message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message.failureKey.tr())));
  }

  Future<void> _pullToRefresh(FeedController controller) async {
    setState(() => _pulling = true);
    try {
      await controller.refresh();
    } finally {
      if (mounted) setState(() => _pulling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final FeedController controller = context.watch<FeedController>();
    final UserSessionService session = GetIt.instance<UserSessionService>();
    final AppPalette colors = context.colors;
    return Scaffold(
      body: SafeArea(
        // A saudação e a busca sobem junto com as notícias; os filtros ficam
        // presos no topo (validação da usuária, specs/024).
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  ValueListenableBuilder<UserSessionStatus>(
                    valueListenable: session.sessionStatus,
                    builder: (context, _, _) => AppTopBar(
                      title: AppStrings.newsTitle.tr(),
                      subtitle: _subtitle(session, controller.newCount),
                    ),
                  ),
                  // Busca e filtros fora da área que troca de estado:
                  // continuam na tela enquanto a lista carrega.
                  FeedSearchField(
                    initialText: controller.filter.search,
                    onChanged: controller.onSearchChanged,
                    onCleared: controller.clearSearch,
                  ),
                  const SizedBox(height: AppSpacing.s3),
                ],
              ),
            ),
            PinnedHeaderSliver(
              child: ColoredBox(
                color: colors.background,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                      child: CategoryFilterBar(
                        categories: controller.categories,
                        selectedSlug: controller.filter.categorySlug,
                        onSelected: controller.selectCategory,
                      ),
                    ),
                    // Troca de categoria ou busca: a lista anterior fica
                    // esmaecida com uma barra fina até a nova chegar (FR-002).
                    SizedBox(
                      height: 2,
                      child: controller.isRefreshing && !_pulling
                          ? LinearProgressIndicator(
                              minHeight: 2,
                              color: colors.primary,
                              backgroundColor: Colors.transparent,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: AnimatedOpacity(
            opacity: controller.isRefreshing && !_pulling ? 0.5 : 1,
            duration: AppMotion.of(context).short,
            curve: AppMotion.standard,
            child: _content(context, controller),
          ),
        ),
      ),
    );
  }

  /// "Olá, Maria! 3 notícias novas para você" (FR-011).
  String _subtitle(UserSessionService session, int newCount) {
    final String? name = session.userName;
    final String greeting =
        session.isAuthenticated && name != null && name.isNotEmpty
        ? AppStrings.newsGreetingNamed.tr(args: [name])
        : AppStrings.newsGreetingGuest.tr();
    if (newCount <= 0) return greeting;
    final String count = newCount == 1
        ? AppStrings.newsNewCountOne.tr()
        : AppStrings.newsNewCount.tr(args: ['$newCount']);
    return '$greeting $count';
  }

  /// Carregando, erro, vazio e lista trocam com um esmaecimento (R8).
  Widget _content(BuildContext context, FeedController controller) =>
      SafeStateSwitcher(
        stateKey: (controller.status, _isEmptyResult(controller)),
        child: _stateContent(context, controller),
      );

  /// Durante a troca de filtro, a lista ainda é a antiga: o vazio só vale
  /// com a resposta do filtro novo.
  bool _isEmptyResult(FeedController controller) =>
      !controller.isRefreshing &&
      controller.items.isEmpty &&
      !controller.filter.isEmpty;

  Widget _stateContent(BuildContext context, FeedController controller) {
    switch (controller.status) {
      case FeedStatus.loading:
        return _FeedSkeleton(now: DateTime.now());
      case FeedStatus.error:
        return SafeErrorState(
          message: (controller.failure?.message ?? AppStrings.errorGeneric)
              .tr(),
          onRetry: controller.load,
        );
      case FeedStatus.loaded:
        if (_isEmptyResult(controller)) {
          return SafeEmptyState(
            message: controller.isSearching
                ? AppStrings.newsEmptySearch.tr(
                    args: [controller.filter.normalizedSearch],
                  )
                : AppStrings.newsEmptyCategory.tr(),
          );
        }
        return RefreshIndicator(
          onRefresh: () => _pullToRefresh(controller),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: _slivers(context, controller),
          ),
        );
    }
  }

  List<Widget> _slivers(BuildContext context, FeedController controller) {
    final DateTime now = DateTime.now();

    // A mesma notícia pode estar em duas seções: a tag leva a seção (R9).
    Future<void> openNews(NewsItemEntity item, String heroTag) =>
        context.push<void>(
          '/news/${item.id}',
          extra: NewsDetailPreview(item: item, heroTag: heroTag),
        );

    Widget card(
      _FeedSection section,
      NewsItemEntity item, {
      bool compact = true,
      double? coverHeight,
    }) {
      final String tag = NewsDetailPreview.tagFor(section.name, item.id);
      return NewsCard(
        item: item,
        now: now,
        compact: compact,
        coverHeight: coverHeight,
        heroTag: tag,
        onTap: () => openNews(item, tag),
      );
    }

    // Destaques: cartões grandes, um por linha.
    Widget large(_FeedSection section, List<NewsItemEntity> items) =>
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s6),
            itemBuilder: (_, index) =>
                card(section, items[index], compact: false),
          ),
        );

    // Recomendadas e Tudo recente: grade de 2 colunas (FR-025).
    Widget cards(_FeedSection section, List<NewsItemEntity> items) =>
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
          sliver: NewsGrid(
            items: items,
            itemBuilder: (item, coverHeight) =>
                card(section, item, coverHeight: coverHeight),
          ),
        );

    return [
      // Feed da cópia guardada (CB-001, FR-020).
      if (controller.isFromCache)
        const SliverToBoxAdapter(child: SafeOfflineBanner()),
      if (controller.reels.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: FeedSectionTitle(AppStrings.newsSectionNew.tr()),
        ),
        SliverToBoxAdapter(
          child: ReelsCarousel(
            reels: controller.reels,
            // O item vai junto: a imagem aparece já na chegada (FR-019).
            onOpen: (item) =>
                context.go('/reels?start=${item.id}', extra: item),
          ),
        ),
      ],
      if (controller.highlights.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: ListenableBuilder(
            listenable: _readAloud,
            builder: (context, _) => FeedSectionTitle(
              AppStrings.newsSectionHighlights.tr(),
              trailing: _readAloud.isContentAvailable
                  ? ListenButton(
                      key: NewsHomePage.highlightsListenKey,
                      isSpeaking: _readAloud.isSpeaking,
                      onPressed: () => _toggleHighlights(controller.highlights),
                    )
                  : null,
            ),
          ),
        ),
        large(_FeedSection.highlights, controller.highlights),
      ],
      if (controller.recommended.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: FeedSectionTitle(AppStrings.newsSectionRecommended.tr()),
        ),
        cards(_FeedSection.recommended, controller.recommended),
      ],
      SliverToBoxAdapter(
        child: FeedSectionTitle(
          controller.isSearching
              ? AppStrings.newsSectionResults.tr()
              : AppStrings.newsSectionRecent.tr(),
        ),
      ),
      cards(_FeedSection.recent, controller.items),
      SliverToBoxAdapter(
        child: FeedListFooter(
          hasMore: controller.hasMore,
          isLoading: controller.isLoadingMore,
          failed: controller.loadMoreFailure != null,
          isEnd: controller.isEnd,
          offlineEnd: controller.isFromCache,
          onLoadMore: controller.loadMore,
        ),
      ),
    ];
  }
}

/// Primeira carga: os cartões do feed em esqueleto (FR-011).
class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const NeverScrollableScrollPhysics(),
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s4,
          AppSpacing.s5,
          0,
        ),
        child: SafeSkeleton(
          enabled: true,
          child: Column(
            children: [
              NewsCard(
                item: NewsPlaceholders.item(0),
                now: now,
                compact: false,
                onTap: () async {},
              ),
              const SizedBox(height: AppSpacing.s6),
              // A mesma grade do feed, em sliver: 4 cartões só.
              CustomScrollView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                slivers: [
                  NewsGrid(
                    items: [
                      for (int index = 1; index < 5; index++)
                        NewsPlaceholders.item(index),
                    ],
                    itemBuilder: (item, coverHeight) => NewsCard(
                      item: item,
                      now: now,
                      coverHeight: coverHeight,
                      onTap: () async {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

/// Seções do feed com cartões: entram na tag do `Hero`, porque a mesma
/// notícia pode estar em duas delas (R9).
enum _FeedSection { highlights, recommended, recent }
