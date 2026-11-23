import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/utils/app_haptics.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/listen_button.dart';
import 'package:click_seguro_app/core/widgets/safe_empty_state.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:click_seguro_app/core/widgets/safe_state_switcher.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/common/services/share_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reel_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/reels_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/reels_status.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_placeholders.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/reel_presentation_extension.dart';
import 'package:click_seguro_app/modules/news/presentation/routes/news_detail_preview.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/reel_actions.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/reel_view.dart';
import 'package:click_seguro_app/modules/shell/shell.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Aba central: Reels em tela cheia, um por vez (RF-013, RF-019,
/// specs/008-reels-curtir-salvar). Sem barra superior; ao lado, só curtir,
/// salvar e compartilhar, e trocar de Reel é arrastando.
///
/// "Ouvir" no começo do texto de cada Reel, acima do título, lê o título e o
/// resumo do Reel na tela. Trocar de Reel para a leitura e, com a leitura
/// automática ligada, lê o novo. Sair da aba ou abrir outra tela também
/// para.
class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key, this.startNewsId, this.preview});

  /// "Ouvir" do Reel [newsId].
  static Key listenKeyFor(String newsId) => ValueKey('reel-listen-$newsId');

  /// `/reels?start=` com o item tocado no carrossel como `extra`; um
  /// `extra` de outra notícia é ignorado.
  factory ReelsPage.fromState(GoRouterState state) {
    final String? start = state.uri.queryParameters['start'];
    return ReelsPage(
      startNewsId: start,
      preview: switch (state.extra) {
        final NewsItemEntity item when item.id == start => item,
        _ => null,
      },
    );
  }

  /// Notícia em que os Reels começam (`/reels?start=`), se houver.
  final String? startNewsId;

  /// O que o carrossel já tem do Reel tocado: a imagem aparece enquanto a
  /// lista carrega (specs/022 FR-019).
  final NewsItemEntity? preview;

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  late final ReelsController _controller;
  StreamSubscription<ReelsMessage>? _messages;
  PageController? _pageController;
  bool _isOpeningDetail = false;
  bool _isSharing = false;
  late final ReadAloudController _readAloud;
  Locale? _locale;

  /// A aba está na tela, sem outra tela por cima ([TickerMode]).
  bool _visible = false;

  /// Reel cuja leitura está em andamento (ou foi a última pedida).
  String? _speakingReelId;

  /// Último Reel lido automaticamente: cada um só uma vez, e "Parar" não
  /// faz ele recomeçar.
  String? _autoReadReelId;

  @override
  void initState() {
    super.initState();
    _readAloud = GetIt.instance<ReadAloudController>()
      ..addListener(_onReadingChanged);
    _controller = context.read<ReelsController>()
      ..addListener(_onControllerChanged)
      ..addListener(_onReadingChanged);
    _messages = _controller.messages.listen(_showMessage);
    // Fora do build: a carga avisa os ouvintes na hora.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.open(widget.startNewsId));
    });
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
    // o `TickerMode` da página.
    final bool visible = TickerMode.valuesOf(context).enabled;
    if (visible == _visible) return;
    _visible = visible;
    // Fora do build: parar e ler avisam os ouvintes na hora.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onReadingChanged());
  }

  @override
  void didUpdateWidget(ReelsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? start = widget.startNewsId;
    if (start != null && start != oldWidget.startNewsId) {
      // Fora do build, como no initState: o didUpdateWidget roda durante a
      // construção e a abertura avisa os ouvintes na hora.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_controller.open(start));
      });
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..removeListener(_onReadingChanged);
    _readAloud
      ..removeListener(_onReadingChanged)
      ..dispose();
    unawaited(_messages?.cancel());
    _pageController?.dispose();
    super.dispose();
  }

  /// Reel na tela, com a lista carregada.
  ReelEntity? get _currentReel => _showsList(_controller)
      ? _controller.reels[_controller.currentIndex]
      : null;

  /// Outro Reel na tela (arrastando ou pelo carrossel), aba escondida ou
  /// lista fora da tela: a leitura do Reel anterior para. Depois, a leitura
  /// automática do Reel atual, se ligada.
  void _onReadingChanged() {
    if (!mounted) return;
    final ReelEntity? current = _currentReel;
    if (_readAloud.isSpeaking &&
        (!_visible || current == null || current.id != _speakingReelId)) {
      unawaited(_readAloud.stop());
    }
    _maybeAutoRead();
  }

  /// Leitura automática (RF-040): uma vez por Reel que aparece, com a voz
  /// pronta e a aba na tela.
  void _maybeAutoRead() {
    final ReelEntity? current = _currentReel;
    if (!_visible ||
        current == null ||
        current.id == _autoReadReelId ||
        !_readAloud.isContentAvailable ||
        !GetIt.instance<AccessibilityPreferencesNotifier>()
            .value
            .autoReadAloud) {
      return;
    }
    _autoReadReelId = current.id;
    _speak(current);
  }

  void _speak(ReelEntity reel) {
    _speakingReelId = reel.id;
    unawaited(_readAloud.speak(reel.spokenText, content: true));
  }

  void _toggleListen(ReelEntity reel) {
    if (_readAloud.isSpeaking && _speakingReelId == reel.id) {
      unawaited(_readAloud.stop());
    } else {
      _speak(reel);
    }
  }

  bool get _isAuthenticated =>
      GetIt.instance<UserSessionService>().isAuthenticated;

  void _showMessage(ReelsMessage message) {
    if (!mounted) return;
    final String text = switch (message.type) {
      ReelsMessageType.saved => AppStrings.newsReelsSavedToast.tr(),
      ReelsMessageType.removed => AppStrings.newsReelsRemovedToast.tr(),
      ReelsMessageType.error =>
        (message.failureKey ?? AppStrings.errorGeneric).tr(),
    };
    _snack(text);
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// O detalhe abre já com o cabeçalho e os botões do Reel, que voam para
  /// o topo dele ([NewsActionsPreview]).
  Future<void> _openDetail(ReelEntity reel) async {
    if (_isOpeningDetail) return;
    _isOpeningDetail = true;
    try {
      await context.push<void>(
        '/news/${reel.id}',
        extra: NewsDetailPreview(
          item: reel.news,
          actions: NewsActionsPreview(
            isLiked: reel.isLiked,
            likesCount: reel.likesCount,
            isSaved: _isAuthenticated && reel.isSaved,
          ),
        ),
      );
    } finally {
      _isOpeningDetail = false;
    }
  }

  /// Pulsos pedidos por Reel: dois toques num Reel já curtido só animam.
  final Map<String, int> _likePulses = {};

  /// O botão alterna; dois toques na imagem ([onlyLike]) só curtem
  /// (specs/022 FR-021). Uma vibração por ação (FR-028).
  Future<void> _like(ReelEntity reel, {bool onlyLike = false}) async {
    if (!await requireAccount(context)) return;
    unawaited(AppHaptics.selection());
    if (onlyLike && reel.isLiked) {
      setState(() => _likePulses[reel.id] = (_likePulses[reel.id] ?? 0) + 1);
      return;
    }
    unawaited(_controller.toggleLike(reel.id));
  }

  Future<void> _save(ReelEntity reel) async {
    if (await requireAccount(context)) {
      unawaited(_controller.toggleSave(reel.id));
    }
  }

  /// Menu do aparelho; cancelar ou falhar não mostra aviso. Sem conta
  /// também vale (RN-003).
  Future<void> _share(ReelEntity reel) async {
    if (_isSharing) return;
    _isSharing = true;
    try {
      await GetIt.instance<ShareService>().shareText(
        reel.shareText,
        subject: reel.news.title,
      );
    } finally {
      _isSharing = false;
    }
  }

  /// O `start` do carrossel muda o índice por fora do gesto: o `PageView`
  /// acompanha. Uma nova carga passa por `loading`, que descarta o
  /// controller de página ([_resetPages]).
  PageController _pageControllerFor(ReelsController controller) {
    final PageController pages = _pageController ??= PageController(
      initialPage: controller.currentIndex,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !pages.hasClients) return;
      final double page = pages.page ?? pages.initialPage.toDouble();
      if ((page - controller.currentIndex).abs() >= 1) {
        pages.jumpToPage(controller.currentIndex);
      }
    });
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final ReelsController controller = context.watch<ReelsController>();
    // Ícones claros na barra de status sobre o fundo escuro (R11).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _content(controller),
      ),
    );
  }

  /// A lista aparece só com Reels carregados.
  static bool _showsList(ReelsController controller) =>
      controller.status == ReelsStatus.loaded && controller.reels.isNotEmpty;

  /// Fora da lista (carregando, erro, vazio), a próxima lista começa num
  /// `PageView` novo, no índice do controller. Feito ao mudar o estado, não
  /// no `build`.
  void _onControllerChanged() {
    if (_showsList(_controller)) return;
    final PageController? pages = _pageController;
    _pageController = null;
    // Ainda preso ao PageView do quadro atual: descarta depois dele.
    if (pages != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => pages.dispose());
    }
  }

  /// Carregando, erro, vazio e lista trocam com um esmaecimento (R8).
  Widget _content(ReelsController controller) => SafeStateSwitcher(
    stateKey: switch (controller.status) {
      ReelsStatus.initial || ReelsStatus.loading => ReelsStatus.loading,
      final ReelsStatus status => (status, _showsList(controller)),
    },
    child: _stateContent(controller),
  );

  Widget _stateContent(ReelsController controller) {
    switch (controller.status) {
      case ReelsStatus.initial:
      case ReelsStatus.loading:
        return _ReelSkeleton(preview: widget.preview);
      case ReelsStatus.error:
        return _Dark(
          child: SafeErrorState(
            failure: controller.failure,
            onRetry: controller.retry,
          ),
        );
      case ReelsStatus.loaded:
        if (controller.reels.isEmpty) {
          return _Dark(
            child: SafeEmptyState(
              message: AppStrings.newsReelsEmpty.tr(),
              actionLabel: AppStrings.newsReelsRefresh.tr(),
              onAction: controller.refresh,
            ),
          );
        }
        return _pageView(controller);
    }
  }

  Widget _pageView(ReelsController controller) {
    final DateTime now = DateTime.now();
    final bool isAuthenticated = _isAuthenticated;
    final List<ReelEntity> reels = controller.reels;
    return PageView.builder(
      controller: _pageControllerFor(controller),
      scrollDirection: Axis.vertical,
      itemCount: reels.length,
      onPageChanged: (index) {
        controller.setIndex(index);
        // O próximo já decodificado: rolar não mostra tela preta (R11).
        if (index + 1 < reels.length) {
          unawaited(ReelView.precache(context, reels[index + 1].news.imageUrl));
        }
      },
      itemBuilder: (context, index) {
        final ReelEntity reel = reels[index];
        final bool isSaved = isAuthenticated && reel.isSaved;
        return ReelView(
          reel: reel,
          now: now,
          onReadFull: () => unawaited(_openDetail(reel)),
          footer: index == reels.length - 1 ? _footer(controller) : null,
          onDoubleTap: () => unawaited(_like(reel, onlyLike: true)),
          listen: ListenableBuilder(
            listenable: _readAloud,
            builder: (context, _) => _readAloud.isContentAvailable
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                    child: ListenButton(
                      key: ReelsPage.listenKeyFor(reel.id),
                      isSpeaking:
                          _readAloud.isSpeaking && _speakingReelId == reel.id,
                      onPressed: () => _toggleListen(reel),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          actions: ReelActions(
            heroTags: NewsActionsPreview.tagsFor(reel.id),
            isLiked: reel.isLiked,
            likesText: reel.formattedLikes,
            likeLabel: reel.likeSemanticLabel,
            onLike: () => unawaited(_like(reel)),
            likePulse: _likePulses[reel.id] ?? 0,
            isSaved: isSaved,
            saveLabel: saveSemanticLabel(isSaved: isSaved),
            onSave: () => unawaited(_save(reel)),
            onShare: () => unawaited(_share(reel)),
          ),
        );
      },
    );
  }

  /// No último Reel: carregando mais, falha com "Tentar novamente" ou fim.
  Widget? _footer(ReelsController controller) {
    final textTheme = Theme.of(context).textTheme;
    final TextStyle? style = textTheme.bodySmall?.copyWith(
      color: context.colors.textPrimaryForeground.withValues(alpha: 0.8),
    );
    if (controller.isLoadingMore) {
      return SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.colors.textPrimaryForeground,
        ),
      );
    }
    if (controller.loadMoreFailure != null) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.s2,
        children: [
          Text(
            controller.loadMoreFailure
                .messageKeyOr(AppStrings.newsLoadMoreFailed)
                .tr(),
            style: style,
          ),
          TextButton(
            onPressed: controller.loadMore,
            style: TextButton.styleFrom(
              foregroundColor: context.colors.textPrimaryForeground,
              minimumSize: const Size(48, 48),
            ),
            child: Text(AppStrings.commonTryAgain.tr()),
          ),
        ],
      );
    }
    if (controller.isEnd) {
      return Text(AppStrings.newsEndOfList.tr(), style: style);
    }
    return null;
  }
}

/// Estados comuns sobre o fundo escuro da tela, com texto claro.
class _Dark extends StatelessWidget {
  const _Dark({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppPalette colors = context.colors;
    final Color light = colors.textPrimaryForeground;
    return SafeArea(
      child: Center(
        child: Theme(
          // Os estados de erro e vazio pintam o texto com a paleta: sobre o
          // preto, o texto vira o claro (specs/027 FR-004).
          data: theme.copyWith(
            textTheme: theme.textTheme.apply(
              bodyColor: light,
              displayColor: light,
            ),
            extensions: [
              colors.copyWith(
                textForeground: light,
                textMutedForeground: light.withValues(alpha: 0.78),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Primeira carga: um Reel em esqueleto, escuro como a tela (FR-011).
class _ReelSkeleton extends StatelessWidget {
  const _ReelSkeleton({this.preview});

  /// Com o item do carrossel, a imagem dele fica fora do esqueleto.
  final NewsItemEntity? preview;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color light = context.colors.textPrimaryForeground;
    // Sobre o preto: barras claras e discretas e contêineres pretos (o
    // esqueleto pinta os contêineres com o `card`).
    final ThemeData dark = theme.copyWith(
      extensions: [
        context.colors.copyWith(
          input: light.withValues(alpha: 0.14),
          card: Colors.black,
        ),
      ],
    );
    return Theme(
      data: dark,
      child: SafeSkeleton(
        enabled: true,
        highlightColor: light.withValues(alpha: 0.28),
        child: ReelView(
          reel: NewsPlaceholders.reel(news: preview),
          now: DateTime.now(),
          onReadFull: () {},
          actions: ReelActions(
            isLiked: false,
            likesText: SafeSkeleton.text(1),
            likeLabel: '',
            onLike: () {},
            isSaved: false,
            saveLabel: '',
            onSave: () {},
            onShare: () {},
          ),
        ),
      ),
    );
  }
}
