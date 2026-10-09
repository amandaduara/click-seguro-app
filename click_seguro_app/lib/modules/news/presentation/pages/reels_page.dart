import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_empty_state.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/core/widgets/slow_request_notice.dart';
import 'package:click_seguro_app/modules/common/services/external_launcher_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reel_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/reels_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/reels_status.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/reel_presentation_extension.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/reel_actions.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/reel_view.dart';
import 'package:click_seguro_app/modules/shell/shell.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Aba central: Reels em tela cheia, um por vez (RF-013, RF-019,
/// specs/008-reels-curtir-salvar). Sem barra superior.
class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key, this.startNewsId});

  /// Notícia em que os Reels começam (`/reels?start=`), se houver.
  final String? startNewsId;

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  static const Duration _pageAnimation = Duration(milliseconds: 300);

  late final ReelsController _controller;
  StreamSubscription<ReelsMessage>? _messages;
  PageController? _pageController;
  bool _isOpeningDetail = false;

  @override
  void initState() {
    super.initState();
    _controller = context.read<ReelsController>();
    _messages = _controller.messages.listen(_showMessage);
    // Fora do build: a carga avisa os ouvintes na hora.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.open(widget.startNewsId));
    });
  }

  @override
  void didUpdateWidget(ReelsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? start = widget.startNewsId;
    if (start != null && start != oldWidget.startNewsId) {
      unawaited(_controller.open(start));
    }
  }

  @override
  void dispose() {
    unawaited(_messages?.cancel());
    _pageController?.dispose();
    super.dispose();
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

  Future<void> _openDetail(ReelEntity reel) async {
    if (_isOpeningDetail) return;
    _isOpeningDetail = true;
    try {
      await context.push<void>('/news/${reel.id}');
    } finally {
      _isOpeningDetail = false;
    }
  }

  Future<void> _like(ReelEntity reel) async {
    if (await requireAccount(context)) {
      unawaited(_controller.toggleLike(reel.id));
    }
  }

  Future<void> _save(ReelEntity reel) async {
    if (await requireAccount(context)) {
      unawaited(_controller.toggleSave(reel.id));
    }
  }

  Future<void> _openSource(ReelEntity reel) async {
    final bool opened = await GetIt.instance<ExternalLauncherService>().openUrl(
      reel.news.sourceUrl,
    );
    if (!opened && mounted) _snack(AppStrings.newsReelsOpenSourceFailed.tr());
  }

  void _goTo(int index) {
    unawaited(
      _pageController?.animateToPage(
        index,
        duration: _pageAnimation,
        curve: Curves.easeOut,
      ),
    );
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
    return Scaffold(backgroundColor: Colors.black, body: _content(controller));
  }

  Widget _content(ReelsController controller) {
    switch (controller.status) {
      case ReelsStatus.initial:
      case ReelsStatus.loading:
        _resetPages();
        return _Dark(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SafeLoadingState(),
              SlowRequestNotice(
                active: true,
                message: AppStrings.newsSlowServer.tr(),
              ),
            ],
          ),
        );
      case ReelsStatus.error:
        _resetPages();
        final Failure? failure = controller.failure;
        return _Dark(
          child: SafeErrorState(
            message: (failure?.message ?? AppStrings.errorGeneric).tr(),
            onRetry: controller.retry,
          ),
        );
      case ReelsStatus.loaded:
        if (controller.reels.isEmpty) {
          _resetPages();
          return _Dark(
            child: SafeEmptyState(
              icon: LucideIcons.newspaper,
              message: AppStrings.newsReelsEmpty.tr(),
              actionLabel: AppStrings.newsReelsRefresh.tr(),
              onAction: controller.refresh,
            ),
          );
        }
        return _pageView(controller);
    }
  }

  /// Fora da lista (carregando, erro, vazio), a próxima lista começa num
  /// `PageView` novo, no índice do controller.
  void _resetPages() {
    final PageController? pages = _pageController;
    _pageController = null;
    // Ainda preso ao PageView deste quadro: descarta depois dele.
    if (pages != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => pages.dispose());
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
      onPageChanged: controller.setIndex,
      itemBuilder: (context, index) {
        final ReelEntity reel = reels[index];
        final bool isSaved = isAuthenticated && reel.isSaved;
        return ReelView(
          reel: reel,
          now: now,
          onReadFull: () => unawaited(_openDetail(reel)),
          footer: index == reels.length - 1 ? _footer(controller) : null,
          actions: ReelActions(
            onPrevious: index > 0 ? () => _goTo(index - 1) : null,
            onNext: index < reels.length - 1 ? () => _goTo(index + 1) : null,
            isLiked: reel.isLiked,
            likesText: reel.formattedLikes,
            likeLabel: reel.likeSemanticLabel,
            onLike: () => unawaited(_like(reel)),
            isSaved: isSaved,
            saveLabel: saveSemanticLabel(isSaved: isSaved),
            onSave: () => unawaited(_save(reel)),
            onOpenSource: isOpenableWebUrl(reel.news.sourceUrl)
                ? () => unawaited(_openSource(reel))
                : null,
          ),
        );
      },
    );
  }

  /// No último Reel: carregando mais, falha com "Tentar novamente" ou fim.
  Widget? _footer(ReelsController controller) {
    final textTheme = Theme.of(context).textTheme;
    final TextStyle? style = textTheme.bodySmall?.copyWith(
      color: AppColors.textPrimaryForeground.withValues(alpha: 0.8),
    );
    if (controller.isLoadingMore) {
      return const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.textPrimaryForeground,
        ),
      );
    }
    if (controller.loadMoreFailure != null) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.s2,
        children: [
          Text(AppStrings.newsLoadMoreFailed.tr(), style: style),
          TextButton(
            onPressed: controller.loadMore,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimaryForeground,
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
    return SafeArea(
      child: Center(
        child: Theme(
          data: theme.copyWith(
            textTheme: theme.textTheme.apply(
              bodyColor: AppColors.textPrimaryForeground,
              displayColor: AppColors.textPrimaryForeground,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
