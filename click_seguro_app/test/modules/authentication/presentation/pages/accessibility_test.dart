import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/authentication_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/forgot_password_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/pages/forgot_password_page.dart';
import 'package:click_seguro_app/modules/authentication/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/controller_factory.dart';
import '../../fakes/fake_auth_repository.dart';
import '../../fakes/forgot_password_controller_factory.dart';

/// FR-019 / SC-007: celular pequeno (360×690) com fonte em 1,5×.
void main() {
  late AuthenticationController authController;
  late ForgotPasswordController forgotController;

  setUp(() {
    final repository = FakeAuthRepository();
    authController = buildAuthenticationController(repository);
    forgotController = buildForgotPasswordController(repository);
  });

  Future<void> pumpSmallScreen(WidgetTester tester, String location) async {
    tester.view
      ..physicalSize = const Size(1080, 2070)
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpLocalized(
      tester,
      router: GoRouter(
        initialLocation: location,
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
            builder: (_, _) => ChangeNotifierProvider.value(
              value: forgotController,
              child: const ForgotPasswordPage(),
            ),
          ),
        ],
      ),
    );
  }

  void expectMinTarget(WidgetTester tester, Finder finder) {
    for (final element in finder.evaluate()) {
      final size = tester.getSize(find.byWidget(element.widget).first);
      expect(size.height, greaterThanOrEqualTo(48), reason: '$finder');
      expect(size.width, greaterThanOrEqualTo(48), reason: '$finder');
    }
  }

  testWidgets('login sem overflow, alvos ≥ 48 e rótulos', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSmallScreen(tester, '/login');

    expect(tester.takeException(), isNull);
    expectMinTarget(tester, find.byType(SafeButton));
    expectMinTarget(tester, find.byType(IconButton));
    expectMinTarget(tester, find.byType(TextButton));
    // Um só nó por campo, com o rótulo (não anunciado em dobro).
    for (final label in ['seu@email.com', 'Senha']) {
      final field = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == label,
      );
      expect(tester.getSemantics(field).label, label);
    }
    expect(find.byTooltip('Mostrar senha'), findsOneWidget);

    final guest = find.widgetWithText(SafeButton, 'Continuar sem login');
    await tester.ensureVisible(guest);
    expect(guest.hitTestable(), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('cadastro sem overflow com a lista de regras', (tester) async {
    await pumpSmallScreen(tester, '/login');

    await tester.tap(find.byKey(const ValueKey('auth-mode-register')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final submit = find.widgetWithText(SafeButton, 'Criar conta');
    await tester.ensureVisible(submit);
    expect(submit.hitTestable(), findsOneWidget);
  });

  testWidgets('recuperação sem overflow e com voltar acessível', (
    tester,
  ) async {
    await pumpSmallScreen(tester, '/forgot-password');

    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Voltar'), findsOneWidget);
    expectMinTarget(tester, find.byType(SafeButton));
  });
}
