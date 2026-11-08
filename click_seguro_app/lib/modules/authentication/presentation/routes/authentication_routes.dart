import 'package:click_seguro_app/core/routing/app_fade_page.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/authentication_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/pages/forgot_password_page.dart';
import 'package:click_seguro_app/modules/authentication/presentation/pages/login_page.dart';
import 'package:go_router/go_router.dart';

/// Rotas do módulo, compostas em `app_router.dart`.
final List<RouteBase> authenticationRoutes = [
  // Sair e entrar trocam o contexto do app: esmaece (specs/022 R4).
  GoRoute(
    path: '/login',
    pageBuilder: (context, state) =>
        appFadePage(state, loginPageFor(state.uri)),
  ),
  GoRoute(
    path: '/forgot-password',
    builder: (context, state) =>
        ForgotPasswordPage(initialEmail: state.extra as String?),
  ),
];

/// `/login?mode=register&next=/activities`: abre em "Criar conta" e, ao
/// entrar, vai para `next` (R4 de specs/020-conclusao-modulo-atividades).
/// `next` só vale como caminho interno do app.
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
  );
}
