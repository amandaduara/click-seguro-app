import 'dart:async';

import 'package:click_seguro_app/modules/authentication/presentation/widgets/password_rules_list.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/authentication_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/pages/login_page.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/auth_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/controller_factory.dart';
import '../../fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthenticationController controller;

  setUp(() {
    repository = FakeAuthRepository();
    controller = buildAuthenticationController(repository);
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

  group('US2', () {
    Future<void> openRegister(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('auth-mode-register')));
      await tester.pumpAndSettle();
    }

    Future<void> fillRegister(WidgetTester tester) async {
      await tester.enterText(field('Seu nome'), 'Maria Silva');
      await tester.enterText(field('seu@email.com'), 'maria@exemplo.com');
      await tester.enterText(field('Senha'), 'Senha@123');
      await tester.pump();
    }

    testWidgets('modo cadastro mostra nome e regras e mantém o e-mail', (
      tester,
    ) async {
      await pumpLogin(tester);
      await tester.enterText(field('seu@email.com'), 'maria@exemplo.com');

      await openRegister(tester);

      expect(field('Seu nome'), findsOneWidget);
      expect(find.byType(PasswordRulesList), findsOneWidget);
      expect(find.text('maria@exemplo.com'), findsOneWidget);
    });

    testWidgets('senha forte marca as 5 regras', (tester) async {
      await pumpLogin(tester);
      await openRegister(tester);

      await tester.enterText(field('Senha'), 'Senha@123');
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsNWidgets(5));
    });

    testWidgets('cadastro válido leva ao Início', (tester) async {
      await pumpLogin(tester);
      await openRegister(tester);
      await fillRegister(tester);

      await tapPrimary(tester, 'Criar conta');

      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('e-mail duplicado oferece entrar com o mesmo e-mail', (
      tester,
    ) async {
      repository.registerResult = const Left(EmailAlreadyExistsFailure());
      await pumpLogin(tester);
      await openRegister(tester);
      await fillRegister(tester);

      await tapPrimary(tester, 'Criar conta');
      expect(find.text('Este e-mail já está cadastrado.'), findsOneWidget);
      await tapPrimary(tester, 'Entrar com este e-mail');

      expect(field('Seu nome'), findsNothing);
      expect(find.text('maria@exemplo.com'), findsOneWidget);
    });

    testWidgets('conta criada sem login volta ao entrar com o aviso', (
      tester,
    ) async {
      repository.registerResult = const Left(AccountCreatedFailure());
      await pumpLogin(tester);
      await openRegister(tester);
      await fillRegister(tester);

      await tapPrimary(tester, 'Criar conta');

      expect(field('Seu nome'), findsNothing);
      expect(
        find.text('Conta criada. Entre com seu e-mail e senha.'),
        findsOneWidget,
      );
    });
  });

  group('US3', () {
    testWidgets('continuar sem login aparece nos dois modos e leva ao Início', (
      tester,
    ) async {
      await pumpLogin(tester);
      expect(find.text('ou'), findsOneWidget);
      expect(find.text('Continuar sem login'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('auth-mode-register')));
      await tester.pumpAndSettle();
      expect(find.text('Continuar sem login'), findsOneWidget);

      await tapPrimary(tester, 'Continuar sem login');

      expect(find.text('HOME'), findsOneWidget);
      expect(repository.guestCalls, 1);
    });
  });

  group('servidor lento', () {
    testWidgets('mostra o aviso depois de 5 s esperando', (tester) async {
      repository.gate = Completer<void>();
      await pumpLogin(tester);
      await fillLogin(tester);

      await tester.tap(find.widgetWithText(SafeButton, 'Entrar').last);
      await tester.pump(); // reconstrói com isSubmitting = true
      await tester.pump(const Duration(seconds: 6));

      expect(
        find.text('Conectando ao servidor. Isso pode levar até um minuto.'),
        findsOneWidget,
      );
      repository.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });
  });
}
