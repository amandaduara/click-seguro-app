import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/authentication_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/forgot_password_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/pages/forgot_password_page.dart';
import 'package:click_seguro_app/modules/authentication/presentation/pages/login_page.dart';
import 'package:click_seguro_app/core/widgets/safe_pill_tabs.dart';
import 'package:click_seguro_app/core/widgets/safe_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/controller_factory.dart';
import '../../fakes/fake_auth_repository.dart';
import '../../fakes/forgot_password_controller_factory.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthenticationController authController;
  late ForgotPasswordController forgotController;

  setUp(() {
    repository = FakeAuthRepository();
    authController = buildAuthenticationController(repository);
    forgotController = buildForgotPasswordController(repository);
  });

  Future<void> pumpApp(WidgetTester tester) => pumpLocalized(
    tester,
    router: GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, _) => ChangeNotifierProvider.value(
            value: authController,
            child: const LoginPage(),
          ),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (_, state) => ChangeNotifierProvider.value(
            value: forgotController,
            child: ForgotPasswordPage(initialEmail: state.extra as String?),
          ),
        ),
        GoRoute(path: '/home', builder: (_, _) => const Text('HOME')),
      ],
    ),
  );

  Finder field(String placeholder) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.hintText == placeholder,
  );

  Future<void> tapButton(WidgetTester tester, String label) async {
    final button = find.widgetWithText(SafeButton, label).last;
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> openForgot(WidgetTester tester) async {
    await pumpApp(tester);
    await tester.enterText(field('seu@email.com'), 'maria@exemplo.com');
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();
  }

  /// Desmonta a página para cancelar o timer da contagem.
  Future<void> unmount(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('"Esqueci minha senha" só aparece no modo Entrar', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Esqueci minha senha'), findsOneWidget);

    await tester.tap(registerTab);
    await tester.pumpAndSettle();

    expect(find.text('Esqueci minha senha'), findsNothing);
  });

  testWidgets('abre com o e-mail já digitado', (tester) async {
    await openForgot(tester);

    expect(find.text('Recuperar senha'), findsOneWidget);
    expect(find.text('maria@exemplo.com'), findsOneWidget);
  });

  testWidgets('fluxo completo volta ao login com o e-mail e a mensagem', (
    tester,
  ) async {
    await openForgot(tester);

    await tapButton(tester, 'Enviar código');
    expect(
      find.text('Se houver uma conta com este e-mail, enviamos um código.'),
      findsOneWidget,
    );
    expect(find.text('Reenviar em 60 s'), findsOneWidget);

    await tester.enterText(field('Código recebido'), '123456');
    await tapButton(tester, 'Continuar');
    await tester.enterText(field('Digite a nova senha'), 'Nova@1234');
    await tester.enterText(field('Digite a nova senha de novo'), 'Nova@1234');
    await tapButton(tester, 'Salvar nova senha');

    expect(find.text('Recuperar senha'), findsNothing);
    expect(find.text('maria@exemplo.com'), findsOneWidget);
    expect(
      find.text('Senha alterada. Entre com a nova senha.'),
      findsOneWidget,
    );
  });

  testWidgets('código inválido mantém no passo do código', (tester) async {
    repository.verifyCodeResult = const Left(InvalidRecoveryCodeFailure());
    await openForgot(tester);
    await tapButton(tester, 'Enviar código');

    await tester.enterText(field('Código recebido'), '000000');
    await tapButton(tester, 'Continuar');

    expect(
      find.text('Código inválido. Confira o e-mail ou peça um novo.'),
      findsOneWidget,
    );
    expect(field('Código recebido'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('voltar no passo do código volta ao passo do e-mail', (
    tester,
  ) async {
    await openForgot(tester);
    await tapButton(tester, 'Enviar código');

    await tester.tap(find.byKey(SafePageHeader.defaultBackKey));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(SafeButton, 'Enviar código'), findsOneWidget);
    expect(field('Código recebido'), findsNothing);
  });

  group('botão principal no fim da tela', () {
    Size screenOf(WidgetTester tester) =>
        tester.view.physicalSize / tester.view.devicePixelRatio;

    void expectPinned(WidgetTester tester, String label) {
      final Finder button = find.widgetWithText(SafeButton, label);
      final Finder scroll = find.byType(SingleChildScrollView);
      final Size screen = screenOf(tester);

      expect(button, findsOneWidget);
      expect(find.descendant(of: scroll, matching: button), findsNothing);
      final Rect rect = tester.getRect(button);
      expect(screen.height - rect.bottom, greaterThan(0));
      expect(screen.height - rect.bottom, lessThanOrEqualTo(48));
      expect(rect.top, greaterThanOrEqualTo(tester.getRect(scroll).bottom));
    }

    testWidgets('fixo embaixo, fora da rolagem, em cada passo', (tester) async {
      await openForgot(tester);
      expectPinned(tester, 'Enviar código');

      await tapButton(tester, 'Enviar código');
      expectPinned(tester, 'Continuar');
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.text('Reenviar em 60 s'),
        ),
        findsOneWidget,
      );

      await tester.enterText(field('Código recebido'), '123456');
      await tapButton(tester, 'Continuar');
      expectPinned(tester, 'Salvar nova senha');
    });

    testWidgets('acima da área segura do Android', (tester) async {
      tester.view.padding = const FakeViewPadding(bottom: 48 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await openForgot(tester);

      final Rect rect = tester.getRect(
        find.widgetWithText(SafeButton, 'Enviar código'),
      );

      expect(rect.bottom, lessThanOrEqualTo(screenOf(tester).height - 48));
      expect(rect.bottom, greaterThan(screenOf(tester).height - 48 - 48));
    });

    testWidgets('com o teclado aberto continua visível e tocável', (
      tester,
    ) async {
      await openForgot(tester);
      tester.view.viewInsets = FakeViewPadding(
        bottom: 300 * tester.view.devicePixelRatio,
      );
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      final Rect rect = tester.getRect(
        find.widgetWithText(SafeButton, 'Enviar código'),
      );
      expect(rect.bottom, lessThanOrEqualTo(screenOf(tester).height - 300));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Enviar código'));
      await tester.pumpAndSettle();

      expect(repository.requestResetCalls, 1);
      await unmount(tester);
    });
  });
}

/// A aba "Criar conta" do seletor no topo do login.
final Finder registerTab = find.descendant(
  of: find.byType(SafePillTabs),
  matching: find.text('Criar conta'),
);
