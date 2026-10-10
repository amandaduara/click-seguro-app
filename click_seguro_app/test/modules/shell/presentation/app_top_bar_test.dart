import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/shell/presentation/widgets/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../fakes/fake_secure_storage_service.dart';
import '../../../helpers/localized_app.dart';
import '../../../helpers/notifications_provider.dart';
import '../../notifications/fakes/alerts_fixtures.dart';
import '../../notifications/fakes/fake_notifications_repository.dart';

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
      await pumpLocalized(
        tester,
        router: buildRouter(),
        providers: [fakeNotificationsProvider()],
      );

      expect(find.text('Olá, Maria'), findsOneWidget);
      expect(find.text('Notícias seguras'), findsOneWidget);
    });

    testWidgets('visitante → "Bem-vindo"', (tester) async {
      await session.startGuestSession();
      await pumpLocalized(
        tester,
        router: buildRouter(),
        providers: [fakeNotificationsProvider()],
      );

      expect(find.text('Bem-vindo'), findsOneWidget);
    });

    testWidgets('subtítulo da tela substitui a saudação', (tester) async {
      await signIn();
      await pumpLocalized(
        tester,
        router: buildRouter(subtitle: '3 notícias novas para você'),
        providers: [fakeNotificationsProvider()],
      );

      expect(find.text('3 notícias novas para você'), findsOneWidget);
      expect(find.text('Olá, Maria'), findsNothing);
    });

    testWidgets('acompanha a mudança da sessão', (tester) async {
      await session.startGuestSession();
      await pumpLocalized(
        tester,
        router: buildRouter(),
        providers: [fakeNotificationsProvider()],
      );
      expect(find.text('Bem-vindo'), findsOneWidget);

      await signIn();
      await tester.pumpAndSettle();

      expect(find.text('Olá, Maria'), findsOneWidget);
    });

    testWidgets('subtítulo com 14 px e título com 24 px', (tester) async {
      await signIn();
      await pumpLocalized(
        tester,
        router: buildRouter(),
        providers: [fakeNotificationsProvider()],
      );

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
      await pumpLocalized(
        tester,
        router: buildRouter(),
        providers: [fakeNotificationsProvider()],
      );

      await tester.tap(find.bySemanticsLabel('Configurações'));
      await tester.pumpAndSettle();

      expect(find.text('tela configurações'), findsOneWidget);
    });

    testWidgets('conectada, "Alertas" abre /notifications', (tester) async {
      await signIn();
      await pumpLocalized(
        tester,
        router: buildRouter(),
        providers: [fakeNotificationsProvider()],
      );

      await tester.tap(find.bySemanticsLabel('Alertas'));
      await tester.pumpAndSettle();

      expect(find.text('tela alertas'), findsOneWidget);
    });

    testWidgets('visitante: "Alertas" mostra o convite e não abre', (
      tester,
    ) async {
      await session.startGuestSession();
      await pumpLocalized(
        tester,
        router: buildRouter(),
        providers: [fakeNotificationsProvider()],
      );

      await tester.tap(find.bySemanticsLabel('Alertas'));
      await tester.pumpAndSettle();

      expect(find.text('Entre na sua conta'), findsOneWidget);
      expect(find.text('tela alertas'), findsNothing);
    });

    testWidgets('conectada: o sino mostra o número de não lidos', (
      tester,
    ) async {
      await signIn();
      final repository = FakeNotificationsRepository()
        ..stored = snapshot(
          alerts: [
            alert(newsId: 'a'),
            alert(newsId: 'b'),
            alert(newsId: 'c'),
          ],
        );
      await pumpLocalized(
        tester,
        router: buildRouter(),
        providers: [fakeNotificationsProvider(repository)],
      );

      expect(find.bySemanticsLabel('Alertas, 3 novos'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('visitante toca no sino: convite e nenhuma chamada ao '
        'repository', (tester) async {
      await session.startGuestSession();
      final repository = FakeNotificationsRepository();
      await pumpLocalized(
        tester,
        router: buildRouter(),
        providers: [fakeNotificationsProvider(repository)],
      );

      await tester.tap(find.bySemanticsLabel('Alertas'));
      await tester.pumpAndSettle();

      expect(find.text('Entre na sua conta'), findsOneWidget);
      expect(find.text('tela alertas'), findsNothing);
      expect(repository.getSnapshotCalls, 0);
      expect(repository.receiveCalls, 0);
      expect(repository.fetchCalls, isEmpty);
    });

    testWidgets('dois toques rápidos abrem uma única tela de alertas', (
      tester,
    ) async {
      await signIn();
      final router = buildRouter();
      await pumpLocalized(
        tester,
        router: router,
        providers: [fakeNotificationsProvider()],
      );

      await tester.tap(find.bySemanticsLabel('Alertas'));
      await tester.tap(find.bySemanticsLabel('Alertas'), warnIfMissed: false);
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      expect(find.text('Notícias seguras'), findsOneWidget);
    });

    testWidgets('os dois botões medem pelo menos 48×48', (tester) async {
      await session.startGuestSession();
      await pumpLocalized(
        tester,
        router: buildRouter(),
        providers: [fakeNotificationsProvider()],
      );

      for (final label in ['Alertas', 'Configurações']) {
        final size = tester.getSize(find.bySemanticsLabel(label));
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
      }
    });

    testWidgets('fonte em 200% não estoura a barra', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await signIn();

      await pumpLocalized(
        tester,
        router: buildRouter(),
        providers: [fakeNotificationsProvider()],
      );

      expect(tester.takeException(), isNull);
    });
  });
}
