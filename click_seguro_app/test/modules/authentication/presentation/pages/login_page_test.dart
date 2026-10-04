import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/login_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/validators/credentials_validator.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/authentication_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/pages/login_page.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/auth_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_auth_repository.dart';

void main() {
  const validator = CredentialsValidator();
  late FakeAuthRepository repository;
  late AuthenticationController controller;

  setUp(() {
    repository = FakeAuthRepository();
    controller = AuthenticationController(
      login: LoginUseCase(repository, validator),
    );
  });

  Future<void> pumpLogin(WidgetTester tester) => pumpLocalized(
    tester,
    router: GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, _) => ChangeNotifierProvider.value(
            value: controller,
            child: const LoginPage(),
          ),
        ),
        GoRoute(path: '/home', builder: (_, _) => const Text('HOME')),
      ],
    ),
  );

  Finder field(String placeholder) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.hintText == placeholder,
  );

  Future<void> fillLogin(
    WidgetTester tester, {
    String email = 'maria@exemplo.com',
  }) async {
    await tester.enterText(field('seu@email.com'), email);
    await tester.enterText(field('Senha'), 'Senha@123');
  }

  Future<void> tapPrimary(WidgetTester tester, String label) async {
    final button = find.widgetWithText(SafeButton, label).last;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  group('US1', () {
    testWidgets('mostra a marca, os campos e o botão Entrar', (tester) async {
      await pumpLogin(tester);

      expect(find.byType(AuthHeader), findsOneWidget);
      expect(field('seu@email.com'), findsOneWidget);
      expect(field('Senha'), findsOneWidget);
      expect(find.text('Entrar'), findsWidgets);
    });

    testWidgets('credenciais válidas levam ao Início', (tester) async {
      await pumpLogin(tester);
      await fillLogin(tester);

      await tapPrimary(tester, 'Entrar');

      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('senha errada mostra a mensagem e mantém o e-mail', (
      tester,
    ) async {
      repository.loginResult = const Left(InvalidCredentialsFailure());
      await pumpLogin(tester);
      await fillLogin(tester);

      await tapPrimary(tester, 'Entrar');

      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
      expect(find.text('maria@exemplo.com'), findsOneWidget);
    });

    testWidgets('e-mail inválido é marcado sem chamar o serviço', (
      tester,
    ) async {
      await pumpLogin(tester);
      await fillLogin(tester, email: 'maria@');

      await tapPrimary(tester, 'Entrar');

      expect(find.text('Digite um e-mail válido.'), findsOneWidget);
      expect(repository.loginCalls, 0);
    });

    testWidgets('o olho mostra e oculta a senha', (tester) async {
      await pumpLogin(tester);
      await tester.enterText(field('Senha'), 'Senha@123');

      expect(tester.widget<TextField>(field('Senha')).obscureText, isTrue);
      await tester.tap(find.byTooltip('Mostrar senha'));
      await tester.pump();

      expect(tester.widget<TextField>(field('Senha')).obscureText, isFalse);
      expect(find.byTooltip('Ocultar senha'), findsOneWidget);
    });
  });
}
