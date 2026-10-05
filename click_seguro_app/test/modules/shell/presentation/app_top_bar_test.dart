import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/shell/presentation/widgets/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../fakes/fake_secure_storage_service.dart';
import '../../../helpers/localized_app.dart';

void main() {
  late UserSessionService session;

  setUp(() {
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> signIn() => session.saveSession(
    accessToken: 'acesso-1',
    refreshToken: 'renovacao-1',
    email: 'maria@exemplo.com',
    userName: 'Maria',
  );

  GoRouter buildRouter({String? subtitle}) => GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: AppTopBar(title: 'Notícias seguras', subtitle: subtitle),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const Scaffold(body: Text('tela configurações')),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const Scaffold(body: Text('tela alertas')),
      ),
    ],
  );

  group('saudação', () {
    testWidgets('conectada → "Olá, Maria" e o título', (tester) async {
      await signIn();
      await pumpLocalized(tester, router: buildRouter());

      expect(find.text('Olá, Maria'), findsOneWidget);
      expect(find.text('Notícias seguras'), findsOneWidget);
    });

    testWidgets('visitante → "Bem-vindo"', (tester) async {
      await session.startGuestSession();
      await pumpLocalized(tester, router: buildRouter());

      expect(find.text('Bem-vindo'), findsOneWidget);
    });

    testWidgets('subtítulo da tela substitui a saudação', (tester) async {
      await signIn();
      await pumpLocalized(
        tester,
        router: buildRouter(subtitle: '3 notícias novas para você'),
      );

      expect(find.text('3 notícias novas para você'), findsOneWidget);
      expect(find.text('Olá, Maria'), findsNothing);
    });

    testWidgets('acompanha a mudança da sessão', (tester) async {
      await session.startGuestSession();
      await pumpLocalized(tester, router: buildRouter());
      expect(find.text('Bem-vindo'), findsOneWidget);

      await signIn();
      await tester.pumpAndSettle();

      expect(find.text('Olá, Maria'), findsOneWidget);
    });

    testWidgets('subtítulo com 14 px e título com 24 px', (tester) async {
      await signIn();
      await pumpLocalized(tester, router: buildRouter());

      expect(tester.widget<Text>(find.text('Olá, Maria')).style?.fontSize, 14);
      expect(
        tester.widget<Text>(find.text('Notícias seguras')).style?.fontSize,
        24,
      );
    });
  });

  group('botões', () {
    testWidgets('"Configurações" abre /settings', (tester) async {
      await session.startGuestSession();
      await pumpLocalized(tester, router: buildRouter());

      await tester.tap(find.bySemanticsLabel('Configurações'));
      await tester.pumpAndSettle();

      expect(find.text('tela configurações'), findsOneWidget);
    });

    testWidgets('conectada, "Notificações" abre /notifications', (
      tester,
    ) async {
      await signIn();
      await pumpLocalized(tester, router: buildRouter());

      await tester.tap(find.bySemanticsLabel('Notificações'));
      await tester.pumpAndSettle();

      expect(find.text('tela alertas'), findsOneWidget);
    });

    testWidgets('visitante: "Notificações" mostra o convite e não abre', (
      tester,
    ) async {
      await session.startGuestSession();
      await pumpLocalized(tester, router: buildRouter());

      await tester.tap(find.bySemanticsLabel('Notificações'));
      await tester.pumpAndSettle();

      expect(find.text('Entre na sua conta'), findsOneWidget);
      expect(find.text('tela alertas'), findsNothing);
    });

    testWidgets('dois toques rápidos abrem uma única tela de alertas', (
      tester,
    ) async {
      await signIn();
      final router = buildRouter();
      await pumpLocalized(tester, router: router);

      await tester.tap(find.bySemanticsLabel('Notificações'));
      await tester.tap(
        find.bySemanticsLabel('Notificações'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      expect(find.text('Notícias seguras'), findsOneWidget);
    });

    testWidgets('os dois botões medem pelo menos 48×48', (tester) async {
      await session.startGuestSession();
      await pumpLocalized(tester, router: buildRouter());

      for (final label in ['Notificações', 'Configurações']) {
        final size = tester.getSize(find.bySemanticsLabel(label));
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
      }
    });

    testWidgets('fonte em 200% não estoura a barra', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await signIn();

      await pumpLocalized(tester, router: buildRouter());

      expect(tester.takeException(), isNull);
    });
  });
}
