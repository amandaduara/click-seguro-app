import 'package:click_seguro_app/core/routing/navigator_keys.dart';
import 'package:click_seguro_app/modules/news/presentation/pages/news_detail_page.dart';
import 'package:click_seguro_app/modules/news/presentation/pages/news_home_page.dart';
import 'package:click_seguro_app/modules/news/presentation/pages/reels_page.dart';
import 'package:go_router/go_router.dart';

/// Raiz da aba Início (aba 0).
final GoRoute newsHomeRoute = GoRoute(
  path: '/home',
  builder: (context, state) => const NewsHomePage(),
);

/// Raiz da aba Notícias/Reels (aba central).
final GoRoute newsReelsRoute = GoRoute(
  path: '/reels',
  builder: (context, state) =>
      ReelsPage(startNewsId: state.uri.queryParameters['start']),
);

/// Telas do módulo sobre as abas.
final List<RouteBase> newsRoutes = [
  GoRoute(
    path: '/news/:id',
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) =>
        NewsDetailPage(newsId: state.pathParameters['id']!),
  ),
];
