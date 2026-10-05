import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_empty_state.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/core/widgets/safe_offline_banner.dart';
import 'package:click_seguro_app/core/widgets/slow_request_notice.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/feed_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/feed_status.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/category_filter_bar.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/feed_list_footer.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/feed_search_field.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/feed_section_title.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_card.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/reels_carousel.dart';
import 'package:click_seguro_app/modules/shell/shell.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Aba Início: o feed de notícias (specs/006-feed-inicio).
class NewsHomePage extends StatelessWidget {
  const NewsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final FeedController controller = context.watch<FeedController>();
    final UserSessionService session = GetIt.instance<UserSessionService>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ValueListenableBuilder<UserSessionStatus>(
              valueListenable: session.sessionStatus,
              builder: (context, _, _) => AppTopBar(
                title: AppStrings.newsTitle.tr(),
                subtitle: _subtitle(session, controller.newCount),
              ),
            ),
            // Busca e filtros fora da área que troca de estado: continuam na
            // tela enquanto a lista carrega.
            FeedSearchField(
              initialText: controller.filter.search,
              onChanged: controller.onSearchChanged,
              onCleared: controller.clearSearch,
            ),
            const SizedBox(height: AppSpacing.s3),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s2),
              child: CategoryFilterBar(
                categories: controller.categories,
                selectedSlug: controller.filter.categorySlug,
                onSelected: controller.selectCategory,
              ),
            ),
            Expanded(child: _content(context, controller)),
          ],
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

  Widget _content(BuildContext context, FeedController controller) {
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
        if (controller.items.isEmpty && !controller.filter.isEmpty) {
          return SafeEmptyState(
            message: controller.isSearching
                ? AppStrings.newsEmptySearch.tr(
                    args: [controller.filter.normalizedSearch],
                  )
                : AppStrings.newsEmptyCategory.tr(),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: _slivers(context, controller),
          ),
        );
    }
  }

  List<Widget> _slivers(BuildContext context, FeedController controller) {
    final DateTime now = DateTime.now();

    Future<void> openNews(NewsItemEntity item) =>
        context.push<void>('/news/${item.id}');

    Widget cards(List<NewsItemEntity> items, {bool compact = true}) =>
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
            itemBuilder: (_, index) => NewsCard(
              item: items[index],
              now: now,
              compact: compact,
              onTap: () => openNews(items[index]),
            ),
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
            onOpen: (item) => context.go('/reels?start=${item.id}'),
          ),
        ),
      ],
      if (controller.highlights.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: FeedSectionTitle(AppStrings.newsSectionHighlights.tr()),
        ),
        cards(controller.highlights, compact: false),
      ],
      if (controller.recommended.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: FeedSectionTitle(AppStrings.newsSectionRecommended.tr()),
        ),
        cards(controller.recommended),
      ],
      SliverToBoxAdapter(
        child: FeedSectionTitle(
          controller.isSearching
              ? AppStrings.newsSectionResults.tr()
              : AppStrings.newsSectionRecent.tr(),
        ),
      ),
      cards(controller.items),
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
