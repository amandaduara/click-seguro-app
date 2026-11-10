import 'package:click_seguro_app/core/routing/app_fade_page.dart';
import 'package:click_seguro_app/core/routing/navigator_keys.dart';
import 'package:click_seguro_app/core/routing/not_found_page.dart';
import 'package:click_seguro_app/core/routing/tab_branch_container.dart';
import 'package:click_seguro_app/modules/activities/activities.dart';
import 'package:click_seguro_app/modules/assistant/assistant.dart';
import 'package:click_seguro_app/modules/authentication/authentication.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/help/help.dart';
import 'package:click_seguro_app/modules/news/news.dart';
import 'package:click_seguro_app/modules/notifications/notifications.dart';
import 'package:click_seguro_app/modules/onboarding/onboarding.dart';
import 'package:click_seguro_app/modules/profile/profile.dart';
import 'package:click_seguro_app/modules/settings/settings.dart';
import 'package:click_seguro_app/modules/shell/presentation/widgets/session_expired_listener.dart';
import 'package:click_seguro_app/modules/shell/shell.dart';
import 'package:click_seguro_app/modules/splash/splash.dart';
import 'package:go_router/go_router.dart';

/// Caminhos que não exigem sessão: a saída não redireciona a partir deles.
const Set<String> _publicPaths = {
  '/',
  '/onboarding',
  '/login',
  '/forgot-password',
};

/// Compõe as rotas dos módulos (plano do produto §2). Cada trilha edita só
/// o `{modulo}_routes.dart` do seu módulo; este arquivo fica fechado depois
/// da Fase 0.
GoRouter buildAppRouter(UserSessionService session) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: session.sessionStatus,
    // Só a saída pedida pela pessoa leva ao login; a expiração mantém a tela
    // e é avisada pelo SessionExpiredListener (R4).
    redirect: (context, state) {
      final bool loggedOut =
          session.sessionStatus.value == UserSessionStatus.unauthenticated &&
          session.endReason == SessionEndReason.userLogout;
      return loggedOut && !_publicPaths.contains(state.matchedLocation)
          ? '/login'
          : null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            appFadePage(state, const OnboardingPage()),
      ),
      ...authenticationRoutes,
      // Abas montadas juntas, com esmaecimento na que entra (specs/022 R5).
      StatefulShellRoute(
        pageBuilder: (context, state, navigationShell) => appFadePage(
          state,
          SessionExpiredListener(
            child: AppShell(navigationShell: navigationShell),
          ),
        ),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            TabBranchContainer(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
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
      ...assistantRoutes,
      ...notificationsRoutes,
      ...settingsRoutes,
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
}
