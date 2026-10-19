import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/modules/activities/presentation/pages/activities_dashboard_page.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/module_card.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../helpers/activities_dependencies.dart';
import '../../../../helpers/localized_app.dart';
import '../../../../helpers/notifications_provider.dart';
import '../../fakes/activities_fixtures.dart';
import '../../fakes/fake_activities_repository.dart';

void main() {
  late UserSessionService session;
  late FakeActivitiesRepository repository;
  late GoRouter router;

  GoRouter buildRouter() => GoRouter(
    initialLocation: '/activities',
    routes: [
      GoRoute(
        path: '/activities',
        builder: (_, _) => const ActivitiesDashboardPage(),
        routes: [
          GoRoute(
            path: ':moduleId',
            builder: (_, state) => Scaffold(
              appBar: AppBar(),
              body: Text(
                'page:/activities/${state.pathParameters['moduleId']}',
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('page:/login')),
      ),
    ],
  );

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    await session.saveSession(
      accessToken: 'tk',
      refreshToken: 'rf',
      email: 'maria@exemplo.com',
      userName: 'Maria',
    );
    repository = FakeActivitiesRepository([
      Right(
        dashboard(
          modules: threeModulesJson(m2: 2, m3: 3),
          totalLessonsCompleted: 4,
        ),
      ),
    ]);
    router = buildRouter();
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Future<void> open(
    WidgetTester tester, {
    double textScale = 1.0,
    Locale locale = const Locale('pt', 'BR'),
  }) async {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    registerActivitiesDependencies(GetIt.instance, repository: repository);
    await pumpLocalized(
      tester,
      router: router,
      providers: [fakeNotificationsProvider()],
      locale: locale,
    );
  }

  Finder card(String title) =>
      find.ancestor(of: find.text(title), matching: find.byType(ModuleCard));

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('progresso geral: "4 de 9 lições concluídas" e a barra', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Seu progresso'), findsOneWidget);
    expect(find.text('4 de 9 lições concluídas'), findsOneWidget);
    final LinearProgressIndicator bar = tester.widget(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(4 / 9, 0.0001));
  });

  testWidgets('cartões na ordem, com progresso e status', (tester) async {
    await open(tester);

    final double y1 = tester.getTopLeft(card('Golpes Digitais')).dy;
    final double y3 = tester.getTopLeft(card('Fake News')).dy;
    expect(y1, lessThan(y3));
    expect(
      find.descendant(
        of: card('Golpes Digitais'),
        matching: find.text('0 de 3 lições'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card('Golpes no WhatsApp'),
        matching: find.text('Em andamento'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card('Fake News'), matching: find.text('Concluído')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card('Golpes Digitais'),
        matching: find.text('Não iniciado'),
      ),
      findsOneWidget,
    );
    expect(find.text('Entenda como criminosos clonam contas.'), findsOneWidget);
  });

  testWidgets('módulo sem lições: "Indisponível" e sem progresso geral', (
    tester,
  ) async {
    repository = FakeActivitiesRepository([
      Right(
        dashboard(
          modules: [moduleJson(lessonsCount: 0)],
          totalLessonsAvailable: 0,
        ),
      ),
    ]);
    await open(tester);

    expect(find.text('Indisponível'), findsOneWidget);
    expect(find.text('Este módulo ainda não tem atividades'), findsOneWidget);
    expect(find.text('Seu progresso'), findsNothing);
  });

  testWidgets('sem ícone ou ícone que falha: ícone padrão, sem erro', (
    tester,
  ) async {
    repository = FakeActivitiesRepository([
      Right(dashboard(modules: [moduleJson(iconUrl: null)])),
    ]);
    await open(tester);

    expect(
      find.descendant(
        of: card('Golpes Digitais'),
        matching: find.byIcon(LucideIcons.graduationCap),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  group('layout (FR-003a)', () {
    testWidgets('letra 100%: duas colunas e o terceiro sozinho', (
      tester,
    ) async {
      await open(tester);

      final Rect m1 = tester.getRect(card('Golpes Digitais'));
      final Rect m2 = tester.getRect(card('Golpes no WhatsApp'));
      final Rect m3 = tester.getRect(card('Fake News'));
      expect(m2.top, m1.top);
      expect(m2.left, greaterThan(m1.left));
      expect(m3.top, greaterThan(m1.bottom));
      expect(m3.width, closeTo(m1.width, 0.5));
      final Text description = tester.widget(
        find.text('Aprenda a reconhecer as táticas mais comuns.'),
      );
      expect(description.maxLines, 3);
    });

    testWidgets('letra 115%: uma coluna, descrição inteira', (tester) async {
      await open(tester, textScale: 1.15);

      final Rect m1 = tester.getRect(card('Golpes Digitais'));
      await reveal(tester, card('Golpes no WhatsApp'));
      final Text description = tester.widget(
        find.text('Aprenda a reconhecer as táticas mais comuns.'),
      );
      expect(description.maxLines, isNull);
      final Rect m2 = tester.getRect(card('Golpes no WhatsApp'));
      expect(m2.left, m1.left);
    });

    testWidgets('mudar a letra com o painel aberto reorganiza sem recarregar', (
      tester,
    ) async {
      await open(tester);
      final int calls = repository.calls;

      tester.platformDispatcher.textScaleFactorTestValue = 1.15;
      await tester.pumpAndSettle();

      final Rect m1 = tester.getRect(card('Golpes Digitais'));
      await reveal(tester, card('Golpes no WhatsApp'));
      expect(tester.getRect(card('Golpes no WhatsApp')).left, m1.left);
      expect(repository.calls, calls);
    });

    testWidgets('celular com letra 2×: sem estouro', (tester) async {
      tester.view
        ..physicalSize = const Size(1080, 2340)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await open(tester, textScale: 2.0);
      await reveal(tester, card('Fake News'));

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('cartão lido como um item com título, status e progresso', (
    tester,
  ) async {
    await open(tester);

    final String label = tester
        .getSemantics(card('Golpes no WhatsApp'))
        .getSemanticsData()
        .label;
    expect(label, contains('Golpes no WhatsApp'));
    expect(label, contains('Em andamento'));
    expect(label, contains('2 de 3 lições'));
    expect(label, contains('Entenda como criminosos clonam contas.'));
  });

  group('abrir (US2)', () {
    testWidgets('tocar no cartão abre o módulo', (tester) async {
      await open(tester);

      await tester.tap(find.text('Golpes Digitais'));
      await tester.pumpAndSettle();

      expect(find.text('page:/activities/m1'), findsOneWidget);
    });

    testWidgets('dois toques rápidos abrem uma tela só', (tester) async {
      await open(tester);

      await tester.tap(find.text('Golpes Digitais'));
      await tester.tap(find.text('Golpes Digitais'), warnIfMissed: false);
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      expect(find.text('page:/activities/m1'), findsNothing);
      expect(find.byType(ActivitiesDashboardPage), findsOneWidget);
    });

    testWidgets('módulo indisponível não abre nem é botão', (tester) async {
      repository = FakeActivitiesRepository([
        Right(
          dashboard(
            modules: [moduleJson(lessonsCount: 0)],
            totalLessonsAvailable: 0,
          ),
        ),
      ]);
      await open(tester);

      await tester.tap(find.text('Golpes Digitais'));
      await tester.pumpAndSettle();

      expect(find.text('page:/activities/m1'), findsNothing);
      expect(
        tester
            .getSemantics(card('Golpes Digitais'))
            .getSemanticsData()
            .flagsCollection
            .isButton,
        isFalse,
      );
    });

    testWidgets('voltar do módulo recarrega sem mostrar carregando', (
      tester,
    ) async {
      repository = FakeActivitiesRepository([
        Right(dashboard(totalLessonsCompleted: 0)),
        Right(
          dashboard(modules: threeModulesJson(m1: 1), totalLessonsCompleted: 1),
        ),
      ]);
      await open(tester);

      await tester.tap(find.text('Golpes Digitais'));
      await tester.pumpAndSettle();
      router.pop();
      await tester.pump();

      expect(find.byType(SafeLoadingState), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('1 de 9 lições concluídas'), findsOneWidget);
    });
  });

  testWidgets('em inglês', (tester) async {
    await open(tester, locale: const Locale('en', 'US'));

    expect(find.text('Your progress'), findsOneWidget);
    expect(find.text('4 of 9 lessons completed'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
  });
}
