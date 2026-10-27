import 'package:click_seguro_app/core/routing/navigator_keys.dart';
import 'package:click_seguro_app/modules/activities/presentation/pages/activities_dashboard_page.dart';
import 'package:click_seguro_app/modules/activities/presentation/pages/lesson_page.dart';
import 'package:go_router/go_router.dart';

/// Raiz da aba Atividades, com a tela de perguntas sobre as abas.
final GoRoute activitiesTabRoute = GoRoute(
  path: '/activities',
  builder: (context, state) => const ActivitiesDashboardPage(),
  routes: [
    GoRoute(
      path: ':moduleId',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) =>
          LessonPage(moduleId: state.pathParameters['moduleId']!),
    ),
  ],
);
