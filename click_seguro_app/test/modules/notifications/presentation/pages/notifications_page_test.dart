import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/widgets/safe_offline_banner.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';
import 'package:click_seguro_app/modules/notifications/presentation/pages/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../helpers/localized_app.dart';
import '../../../../helpers/notifications_provider.dart';
import '../../fakes/alerts_fixtures.dart';
import '../../fakes/fake_notifications_repository.dart';

void main() {
  late UserSessionService session;
  late FakeNotificationsRepository repository;
  late GoRouter router;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    await session.saveSession(
      accessToken: 'tk',
      refreshToken: 'rf',
      email: 'ana@test.com',
    );
    repository = FakeNotificationsRepository();
    router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationsPage(),
        ),
        GoRoute(
          path: '/news/:id',
          builder: (_, state) => Scaffold(
            appBar: AppBar(),
            body: Text('detalhe ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
  });

  tearDown(() async => GetIt.instance.reset());

  /// Meio-dia local, [days] dias antes do "hoje" dos testes (o agrupamento
  /// usa o dia local).
  DateTime noon(int days) {
    final DateTime local = testNow.toLocal();
    return DateTime(local.year, local.month, local.day - days, 12);
  }

  AlertEntity alertAt(
    String id,
    DateTime publishedAt, {
    bool isRead = false,
    String title = 'Golpe do Pix',
  }) => alert(
    newsId: id,
    title: '$title $id',
    publishedAt: publishedAt,
    isRead: isRead,
  );

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpLocalized(
      tester,
      router: router,
      providers: [fakeNotificationsProvider(repository)],
    );
  }

  final Finder inScroll = find.byType(Scrollable);

  Finder textInScroll(String text) =>
      find.descendant(of: inScroll, matching: find.text(text));

  group('lista', () {
    testWidgets('abrir a tela confere de novo, sem esperar o intervalo', (
      tester,
    ) async {
      repository.stored = snapshot(alerts: [alertAt('a', noon(0))]);

      await pumpPage(tester);

      expect(repository.receiveCalls, 1);
      expect(repository.fetchCalls, hasLength(1));
    });

    testWidgets('título "Alertas" na barra', (tester) async {
      await pumpPage(tester);

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Alertas'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('grupos Hoje, Ontem e Anteriores, na ordem', (tester) async {
      repository.stored = snapshot(
        alerts: [
          alertAt('old', noon(5)),
          alertAt('today', noon(0)),
          alertAt('yest', noon(1)),
        ],
      );

      await pumpPage(tester);

      final double today = tester.getTopLeft(find.text('Hoje')).dy;
      final double yesterday = tester.getTopLeft(find.text('Ontem')).dy;
      final double earlier = tester.getTopLeft(find.text('Anteriores')).dy;
      expect(today, lessThan(yesterday));
      expect(yesterday, lessThan(earlier));
    });

    testWidgets('sem grupo vazio', (tester) async {
      repository.stored = snapshot(alerts: [alertAt('today', noon(0))]);

      await pumpPage(tester);

      expect(find.text('Hoje'), findsOneWidget);
      expect(find.text('Ontem'), findsNothing);
      expect(find.text('Anteriores'), findsNothing);
    });

    testWidgets('cada alerta mostra título, fonte e hora ou data', (
      tester,
    ) async {
      repository.stored = snapshot(
        alerts: [
          alertAt(
            'today',
            DateTime(noon(0).year, noon(0).month, noon(0).day, 8, 5),
          ),
          alertAt('old', noon(5)),
        ],
      );

      await pumpPage(tester);

      expect(find.text('Golpe do Pix today'), findsOneWidget);
      expect(find.textContaining('Folha de Teste · 08:05'), findsOneWidget);
      final DateTime old = noon(5);
      final String date =
          '${old.day.toString().padLeft(2, '0')}/${old.month.toString().padLeft(2, '0')}';
      expect(find.textContaining('Folha de Teste · $date'), findsOneWidget);
    });

    testWidgets('"Novo" escrito só nos não lidos', (tester) async {
      repository.stored = snapshot(
        alerts: [
          alertAt('a', noon(0)),
          alertAt('b', noon(0), isRead: true),
          alertAt('c', noon(1)),
        ],
      );

      await pumpPage(tester);

      expect(find.text('Novo'), findsNWidgets(2));
    });

    testWidgets('resumo fixo no alto, fora da lista que rola', (tester) async {
      repository.stored = snapshot(
        alerts: [alertAt('a', noon(0)), alertAt('b', noon(0))],
      );

      await pumpPage(tester);

      expect(find.text('Você tem 2 alertas novos'), findsOneWidget);
      expect(textInScroll('Você tem 2 alertas novos'), findsNothing);
      expect(textInScroll('Hoje'), findsOneWidget);
    });

    testWidgets('resumo no singular e sem não lidos', (tester) async {
      repository.stored = snapshot(
        alerts: [alertAt('a', noon(0)), alertAt('b', noon(0), isRead: true)],
      );
      await pumpPage(tester);
      expect(find.text('Você tem 1 alerta novo'), findsOneWidget);

      await tester.tap(find.text('Golpe do Pix a'));
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      expect(find.text('Você não tem alertas novos'), findsOneWidget);
    });

    testWidgets(
      'tocar marca como lido e abre a notícia; ao voltar, sem "Novo"',
      (tester) async {
        repository.stored = snapshot(
          alerts: [alertAt('a', noon(0)), alertAt('b', noon(0))],
        );
        await pumpPage(tester);

        await tester.tap(find.text('Golpe do Pix a'));
        await tester.pumpAndSettle();

        expect(find.text('detalhe a'), findsOneWidget);
        expect(
          repository.stored.alerts.firstWhere((a) => a.newsId == 'a').isRead,
          isTrue,
        );

        router.pop();
        await tester.pumpAndSettle();

        expect(find.text('Novo'), findsOneWidget);
        expect(find.text('Você tem 1 alerta novo'), findsOneWidget);
      },
    );

    testWidgets('toque duplo abre a notícia uma vez', (tester) async {
      repository.stored = snapshot(alerts: [alertAt('a', noon(0))]);
      await pumpPage(tester);

      await tester.tap(find.text('Golpe do Pix a'));
      await tester.tap(find.text('Golpe do Pix a'), warnIfMissed: false);
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      expect(find.text('detalhe a'), findsNothing);
      expect(find.byType(NotificationsPage), findsOneWidget);
    });

    testWidgets('sem alertas: mensagem e explicação', (tester) async {
      await pumpPage(tester);

      expect(find.text('Você não tem alertas.'), findsOneWidget);
      expect(
        find.text('Quando sair uma notícia nova, ela aparece aqui.'),
        findsOneWidget,
      );
      expect(find.text('Marcar todos como lidos'), findsNothing);
    });

    testWidgets('sem internet: faixa fixa no alto e a lista guardada', (
      tester,
    ) async {
      repository.stored = snapshot(alerts: [alertAt('a', noon(0))]);
      repository.receiveAlertsError = const ConnectionFailure();

      await pumpPage(tester);

      expect(find.byType(SafeOfflineBanner), findsOneWidget);
      expect(
        find.descendant(of: inScroll, matching: find.byType(SafeOfflineBanner)),
        findsNothing,
      );
      expect(find.text('Golpe do Pix a'), findsOneWidget);
    });

    testWidgets('outras falhas e sucesso: sem faixa', (tester) async {
      repository.stored = snapshot(alerts: [alertAt('a', noon(0))]);
      repository.newAlertsError = const ServerFailure();

      await pumpPage(tester);

      expect(find.byType(SafeOfflineBanner), findsNothing);
    });

    testWidgets('nenhum SnackBar nem menu de três pontos', (tester) async {
      repository.stored = snapshot(alerts: [alertAt('a', noon(0))]);
      repository.receiveAlertsError = const ConnectionFailure();

      await pumpPage(tester);

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(PopupMenuButton<Object?>), findsNothing);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });
  });
}
