import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/authentication_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/forgot_password_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/pages/forgot_password_page.dart';
import 'package:click_seguro_app/modules/authentication/presentation/pages/login_page.dart';
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

    await tester.tap(find.byKey(const ValueKey('auth-mode-register')));
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
    await tester.enterText(field('Nova senha'), 'Nova@1234');
    await tester.enterText(field('Confirme a nova senha'), 'Nova@1234');
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

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(SafeButton, 'Enviar código'), findsOneWidget);
    expect(field('Código recebido'), findsNothing);
  });
}
