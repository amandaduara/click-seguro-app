import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/shell/shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../fakes/fake_secure_storage_service.dart';
import '../../../helpers/localized_app.dart';

void main() {
  late UserSessionService session;
  late List<bool> results;

  setUp(() {
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    results = [];
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> signIn() => session.saveSession(
    accessToken: 'acesso-1',
    refreshToken: 'renovacao-1',
    email: 'maria@exemplo.com',
    userName: 'Maria',
  );

  GoRouter buildRouter() => GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async => results.add(await requireAccount(context)),
              child: const Text('Ação'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('tela login')),
      ),
    ],
  );

  Future<void> tapAction(WidgetTester tester) async {
    await tester.tap(find.text('Ação'));
    await tester.pumpAndSettle();
  }

  testWidgets('conectada: permite, sem convite', (tester) async {
    await signIn();
    await pumpLocalized(tester, router: buildRouter());

    await tapAction(tester);

    expect(results, [true]);
    expect(find.text('Entre na sua conta'), findsNothing);
  });

  testWidgets('letra no teto de 2× num celular comum: convite sem estourar '
      'e com os dois botões alcançáveis (SC-004 da feature 009)', (
    tester,
  ) async {
    // Pixel 4 (393 × 830 dp), escala total máxima da feature 009.
    tester.view.physicalSize = const Size(1080, 2280);
    tester.view.devicePixelRatio = 2.75;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await session.startGuestSession();
    await pumpLocalized(tester, router: buildRouter());

    await tapAction(tester);
    await tester.ensureVisible(find.text('Agora não'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agora não'));
    await tester.pumpAndSettle();

    expect(results, [false]);
    expect(find.text('Entre na sua conta'), findsNothing);
  });

  testWidgets('visitante: mostra o convite completo', (tester) async {
    await session.startGuestSession();
    await pumpLocalized(tester, router: buildRouter());

    await tapAction(tester);

    expect(find.text('Entre na sua conta'), findsOneWidget);
    expect(
      find.text(
        'Para usar esta função, entre ou crie uma conta. É rápido e gratuito.',
      ),
      findsOneWidget,
    );
    expect(find.text('Entrar ou criar conta'), findsOneWidget);
    expect(find.text('Agora não'), findsOneWidget);
  });

  testWidgets('"Agora não" fecha, devolve false e mantém a tela', (
    tester,
  ) async {
    await session.startGuestSession();
    await pumpLocalized(tester, router: buildRouter());
    await tapAction(tester);

    await tester.tap(find.text('Agora não'));
    await tester.pumpAndSettle();

    expect(results, [false]);
    expect(find.text('Entre na sua conta'), findsNothing);
    expect(find.text('Ação'), findsOneWidget);
  });

  testWidgets('"Entrar ou criar conta" leva ao login', (tester) async {
    await session.startGuestSession();
    await pumpLocalized(tester, router: buildRouter());
    await tapAction(tester);

    await tester.tap(find.text('Entrar ou criar conta'));
    await tester.pumpAndSettle();

    expect(results, [false]);
    expect(find.text('tela login'), findsOneWidget);
  });

  testWidgets('sessão expirada (sem conta) também vê o convite', (
    tester,
  ) async {
    await signIn();
    await session.expire();
    await pumpLocalized(tester, router: buildRouter());

    await tapAction(tester);

    expect(find.text('Entre na sua conta'), findsOneWidget);
  });

  testWidgets('dois toques rápidos abrem um único convite', (tester) async {
    await session.startGuestSession();
    await pumpLocalized(tester, router: buildRouter());

    await tester.tap(find.text('Ação'));
    await tester.tap(find.text('Ação'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Entre na sua conta'), findsOneWidget);
  });

  testWidgets('botões do convite têm pelo menos 48 de altura', (tester) async {
    await session.startGuestSession();
    await pumpLocalized(tester, router: buildRouter());
    await tapAction(tester);

    for (final label in ['Entrar ou criar conta', 'Agora não']) {
      final button = find.ancestor(
        of: find.text(label),
        matching: find.byType(GestureDetector),
      );
      expect(
        tester.getSize(button.first).height,
        greaterThanOrEqualTo(48),
        reason: label,
      );
    }
  });
}
