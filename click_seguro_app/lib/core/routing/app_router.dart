import 'package:click_seguro_app/core/routing/navigator_keys.dart';
import 'package:click_seguro_app/core/routing/not_found_page.dart';
import 'package:click_seguro_app/modules/activities/activities.dart';
import 'package:click_seguro_app/modules/authentication/authentication.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/help/help.dart';
import 'package:click_seguro_app/modules/news/news.dart';
import 'package:click_seguro_app/modules/notifications/notifications.dart';
import 'package:click_seguro_app/modules/onboarding/onboarding.dart';
import 'package:click_seguro_app/modules/profile/profile.dart';
import 'package:click_seguro_app/modules/settings/settings.dart';
import 'package:click_seguro_app/modules/shell/shell.dart';
import 'package:click_seguro_app/modules/splash/splash.dart';
import 'package:go_router/go_router.dart';

/// Compõe as rotas dos módulos (plano do produto §2). Cada trilha edita só
/// o `{modulo}_routes.dart` do seu módulo; este arquivo fica fechado depois
/// da Fase 0.
GoRouter buildAppRouter(UserSessionService session) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      ...authenticationRoutes,
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        // Na ordem do AppTab.
        branches: [
          newsHomeRoute,
          activitiesTabRoute,
          newsReelsRoute,
          helpTabRoute,
          profileTabRoute,
        ].map((route) => StatefulShellBranch(routes: [route])).toList(),
      ),
      ...newsRoutes,
      ...notificationsRoutes,
      ...settingsRoutes,
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
}
