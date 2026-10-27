import 'dart:async';

import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/core/widgets/safe_offline_banner.dart';
import 'package:click_seguro_app/core/widgets/safe_state_illustration.dart';
import 'package:click_seguro_app/core/widgets/slow_request_notice.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_list_kind.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/feed_status.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/user_news_list_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/feed_list_footer.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Notícias salvas (RF-019, specs/010-detalhe-noticia), lidas ou curtidas
/// (specs/012-perfil, R8): cartões do feed, da mais recente para a mais
/// antiga. O visitante vê o convite no lugar da lista, sem pedido ao serviço.
/// O [UserNewsListController] vem da rota e só é usado com conta.
class UserNewsListPage extends StatelessWidget {
  const UserNewsListPage({super.key, required this.kind});

  static const Key loginKey = ValueKey('saved-login');

  final NewsListKind kind;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(kind.title.tr())),
      body: SafeArea(
        child: ValueListenableBuilder<UserSessionStatus>(
          valueListenable: GetIt.instance<UserSessionService>().sessionStatus,
          builder: (context, status, _) =>
              status == UserSessionStatus.authenticated
              ? _UserNewsList(kind: kind)
              : _GuestInvite(kind: kind),
        ),
      ),
    );
  }
}

/// Convite dentro da tela: texto curto e um botão grande para o login.
class _GuestInvite extends StatelessWidget {
  const _GuestInvite({required this.kind});

  final NewsListKind kind;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _iconOf(kind),
              size: 40,
              color: context.colors.textMutedForeground,
            ),
            const SizedBox(height: AppSpacing.s3),
            Semantics(
              header: true,
              child: Text(
                AppStrings.commonAccountRequiredTitle.tr(),
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: context.colors.secondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              kind.guestBody.tr(),
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.s6),
            SafeButton(
              key: UserNewsListPage.loginKey,
              label: AppStrings.commonAccountRequiredAction.tr(),
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista de quem tem conta: carrega ao aparecer e de novo ao voltar de uma
/// notícia (FR-014).
class _UserNewsList extends StatefulWidget {
  const _UserNewsList({required this.kind});

  final NewsListKind kind;

  @override
  State<_UserNewsList> createState() => _UserNewsListState();
}

class _UserNewsListState extends State<_UserNewsList> {
  late final UserNewsListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<UserNewsListController>();
    // Fora do build: a carga avisa os ouvintes na hora.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_controller.load());
    });
  }

  Future<void> _openNews(NewsItemEntity item) async {
    await context.push<void>('/news/${item.id}');
    if (mounted) unawaited(_controller.refresh());
  }

  @override
  Widget build(BuildContext context) {
    final UserNewsListController controller = context
        .watch<UserNewsListController>();
    switch (controller.status) {
      case FeedStatus.loading:
        return Center(
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
      case FeedStatus.error:
        return SafeErrorState(
          message: (controller.failure?.message ?? AppStrings.errorGeneric)
              .tr(),
          onRetry: controller.load,
        );
      case FeedStatus.loaded:
        if (controller.items.isEmpty) return _EmptyList(kind: widget.kind);
        return _list(controller);
    }
  }

  Widget _list(UserNewsListController controller) {
    final DateTime now = DateTime.now();
    final List<NewsItemEntity> items = controller.items;
    return Column(
      children: [
        if (controller.isFromCache) const SafeOfflineBanner(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
            itemBuilder: (_, index) {
              if (index == items.length) {
                return FeedListFooter(
                  hasMore: controller.hasMore,
                  isLoading: controller.isLoadingMore,
                  failed: controller.loadMoreFailure != null,
                  isEnd: controller.isEnd,
                  offlineEnd: controller.isFromCache,
                  onLoadMore: controller.loadMore,
                );
              }
              return NewsCard(
                item: items[index],
                now: now,
                onTap: () => _openNews(items[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// "Você ainda não salvou nenhuma notícia." (ou leu, ou curtiu), a dica e o
/// botão para o Início.
class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.kind});

  final NewsListKind kind;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    // Rolável: com a fonte grande e o botão, pode não caber na tela.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SafeStateIllustration(isError: false, icon: _iconOf(kind)),
            const SizedBox(height: AppSpacing.s3),
            Text(
              kind.empty.tr(),
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colors.textForeground,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              kind.emptyHint.tr(),
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                color: context.colors.textMutedForeground,
              ),
            ),
            const SizedBox(height: AppSpacing.s5),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: SafeButton(
                label: AppStrings.commonBackHome.tr(),
                size: SafeButtonSize.compact,
                onPressed: () => context.go('/home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconOf(NewsListKind kind) => switch (kind) {
  NewsListKind.saved => LucideIcons.bookmark,
  NewsListKind.read => LucideIcons.bookOpenCheck,
  NewsListKind.liked => LucideIcons.heart,
};
