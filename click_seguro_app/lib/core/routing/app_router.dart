import 'package:click_seguro_app/core/routing/home_placeholder_page.dart';
import 'package:click_seguro_app/modules/authentication/authentication.dart';
import 'package:click_seguro_app/modules/onboarding/onboarding.dart';
import 'package:click_seguro_app/modules/splash/splash.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    ...authenticationRoutes,
    // TODO(F0.9): trocar pelo shell com as abas.
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePlaceholderPage(),
    ),
  ],
);
