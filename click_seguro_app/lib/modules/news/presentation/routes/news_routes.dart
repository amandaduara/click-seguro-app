import 'package:click_seguro_app/core/routing/navigator_keys.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_news_detail_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/get_saved_news_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/mark_news_as_read_usecase.dart';
import 'package:click_seguro_app/modules/news/domain/usecases/toggle_save_usecase.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/news_detail_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/saved_news_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/pages/news_detail_page.dart';
import 'package:click_seguro_app/modules/news/presentation/pages/news_home_page.dart';
import 'package:click_seguro_app/modules/news/presentation/pages/reels_page.dart';
import 'package:click_seguro_app/modules/news/presentation/pages/saved_news_page.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
  // Antes de `/news/:id`: senão "saved" seria lido como identificador
  // (research R1 de specs/010-detalhe-noticia).
  GoRoute(
    path: '/news/saved',
    parentNavigatorKey: rootNavigatorKey,
    // Sem carga aqui: a página só carrega com conta.
    builder: (context, state) => ChangeNotifierProvider(
      create: (_) => SavedNewsController(
        getSavedNews: GetIt.instance<GetSavedNewsUseCase>(),
      ),
      child: const SavedNewsPage(),
    ),
  ),
  GoRoute(
    path: '/news/:id',
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) {
      final String id = state.pathParameters['id']!;
      final GetIt injector = GetIt.instance;
      // Um controller por abertura (data-model de specs/010-detalhe-noticia).
      return ChangeNotifierProvider(
        create: (_) => NewsDetailController(
          getNewsDetail: injector<GetNewsDetailUseCase>(),
          markAsRead: injector<MarkNewsAsReadUseCase>(),
          toggleSave: injector<ToggleSaveUseCase>(),
          sessionStatus: injector<UserSessionService>().sessionStatus,
          newsId: id,
        )..load(),
        child: NewsDetailPage(newsId: id),
      );
    },
  ),
];
