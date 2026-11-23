import 'package:click_seguro_app/modules/authentication/presentation/controller/authentication_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/routes/authentication_routes.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/login_intro.dart';
import 'package:flutter_test/flutter_test.dart';

/// `/login?mode=register&next=…` (R4 de specs/020-conclusao-modulo-atividades).
void main() {
  test('mode=register e next interno', () {
    final page = loginPageFor(
      Uri.parse('/login?mode=register&next=/activities'),
    );

    expect(page.initialMode, AuthMode.register);
    expect(page.next, '/activities');
  });

  test('sem parâmetros: como antes', () {
    final page = loginPageFor(Uri.parse('/login'));

    expect(page.initialMode, AuthMode.login);
    expect(page.next, isNull);
  });

  test('mode desconhecido → login', () {
    expect(
      loginPageFor(Uri.parse('/login?mode=admin')).initialMode,
      AuthMode.login,
    );
  });

  // specs/026 FR-016 a FR-018: só a splash abre o login com a abertura.
  test('from=splash liga a abertura com o voo da marca', () {
    expect(
      loginPageFor(Uri.parse('/login?from=splash')).introFrom,
      LoginIntroOrigin.splash,
    );
  });

  test('from=onboarding liga a entrada com a onda subindo (US5)', () {
    expect(
      loginPageFor(Uri.parse('/login?from=onboarding')).introFrom,
      LoginIntroOrigin.onboarding,
    );
  });

  test('sem from, ou com outra origem, não há abertura', () {
    for (final String location in [
      '/login',
      '/login?mode=register&next=/activities',
      '/login?from=settings',
    ]) {
      expect(
        loginPageFor(Uri.parse(location)).introFrom,
        isNull,
        reason: location,
      );
    }
  });

  test('next externo é ignorado', () {
    for (final next in ['https://x.com', '//x.com', 'activities', '']) {
      expect(
        loginPageFor(
          Uri.parse('/login').replace(queryParameters: {'next': next}),
        ).next,
        isNull,
        reason: next,
      );
    }
  });
}
