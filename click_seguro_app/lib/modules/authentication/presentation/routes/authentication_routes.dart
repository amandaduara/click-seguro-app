import 'package:click_seguro_app/core/routing/app_fade_page.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/authentication_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/pages/forgot_password_page.dart';
import 'package:click_seguro_app/modules/authentication/presentation/pages/login_page.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/login_intro.dart';
import 'package:go_router/go_router.dart';

/// Rotas do módulo, compostas em `app_router.dart`.
final List<RouteBase> authenticationRoutes = [
  // Sair e entrar trocam o contexto do app: esmaece (specs/022 R4).
  GoRoute(
    path: '/login',
    pageBuilder: (context, state) {
      final LoginPage page = loginPageFor(state.uri);
      // Vindo da splash ou do onboarding, troca seca: o próprio login faz a
      // entrada (specs/026 R1 e US5).
      return page.introFrom != null
          ? NoTransitionPage<void>(key: state.pageKey, child: page)
          : appFadePage(state, page);
    },
  ),
  GoRoute(
    path: '/forgot-password',
    builder: (context, state) =>
        ForgotPasswordPage(initialEmail: state.extra as String?),
  ),
];

/// `/login?mode=register&next=/activities`: abre em "Criar conta" e, ao
/// entrar, vai para `next` (R4 de specs/020-conclusao-modulo-atividades).
/// `next` só vale como caminho interno do app. `from=splash` liga a
/// passagem animada; `from=onboarding`, a entrada com a onda subindo
/// (specs/026).
LoginPage loginPageFor(Uri uri) {
  final Map<String, String> query = uri.queryParameters;
  final String? next = query['next'];
  return LoginPage(
    initialMode: query['mode'] == 'register'
        ? AuthMode.register
        : AuthMode.login,
    next: next != null && next.startsWith('/') && !next.startsWith('//')
        ? next
        : null,
    introFrom: switch (query['from']) {
      'splash' => LoginIntroOrigin.splash,
      'onboarding' => LoginIntroOrigin.onboarding,
      _ => null,
    },
  );
}
