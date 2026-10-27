import 'package:click_seguro_app/modules/authentication/presentation/controller/authentication_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/routes/authentication_routes.dart';
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
