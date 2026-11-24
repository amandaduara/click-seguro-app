import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:click_seguro_app/modules/activities/data/datasources/guest_progress_store.dart';
import 'package:click_seguro_app/modules/activities/data/repositories/activities_repository_impl.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/activities_dashboard_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/repositories/activities_repository.dart';
import 'package:click_seguro_app/modules/activities/domain/usecases/get_activities_dashboard_usecase.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/activities_dashboard_controller.dart';
import 'package:click_seguro_app/modules/activities/presentation/pages/activities_dashboard_page.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/module_card.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/core/widgets/safe_progress.dart';
import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
import 'package:click_seguro_app/core/illustrations/app_illustration.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../helpers/activities_dependencies.dart';
import '../../../../helpers/localized_app.dart';
import '../../../../helpers/notifications_provider.dart';
import '../../fakes/activities_fixtures.dart';
import '../../fakes/fake_activities_remote_data_source.dart';
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
    bool realRepository = false,
    bool settle = true,
  }) async {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    registerActivitiesDependencies(
      GetIt.instance,
      repository: realRepository
          ? GetIt.instance<ActivitiesRepository>()
          : repository,
    );
    if (tester.view.physicalSize == const Size(2400, 1800)) {
      tester.view.physicalSize = const Size(1170, 4800);
      addTearDown(tester.view.resetPhysicalSize);
    }
    await pumpLocalized(
      tester,
      router: router,
      providers: [fakeNotificationsProvider()],
      locale: locale,
      settle: settle,
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
    final SafeProgressRing ring = tester.widget(find.byType(SafeProgressRing));
    expect(ring.value, closeTo(4 / 9, 0.0001));
    expect(ring.label, '44%');
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

  testWidgets('concluído errando a maioria: selo "Refazer" de atenção '
      '(specs/025)', (tester) async {
    repository = FakeActivitiesRepository([
      Right(
        _scored(
          dashboard(
            modules: [moduleJson(completedCount: 3)],
            totalLessonsCompleted: 3,
          ),
          score: 1,
        ),
      ),
    ]);
    await open(tester);

    final Finder badgeIcon = find.descendant(
      of: card('Golpes Digitais'),
      matching: find.byIcon(LucideIcons.rotateCcw),
    );
    expect(
      find.descendant(
        of: card('Golpes Digitais'),
        matching: find.text('Refazer'),
      ),
      findsOneWidget,
    );
    expect(find.text('Concluído'), findsNothing);
    expect(badgeIcon, findsOneWidget);
    expect(
      tester.widget<Icon>(badgeIcon).color,
      tester.element(badgeIcon).colors.warning,
    );
    expect(
      tester.getSemantics(card('Golpes Digitais')).label,
      contains('Refazer'),
    );
  });

  testWidgets('"Refazer" em inglês: "Redo"', (tester) async {
    repository = FakeActivitiesRepository([
      Right(
        _scored(dashboard(modules: [moduleJson(completedCount: 3)]), score: 0),
      ),
    ]);
    await open(tester, locale: const Locale('en', 'US'));

    expect(find.text('Redo'), findsOneWidget);
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

  testWidgets('capa com a ilustração do tema do título (FR-014 de specs/024)', (
    tester,
  ) async {
    await open(tester);

    SafeIllustration coverOf(String title) => tester.widget(
      find.descendant(of: card(title), matching: find.byType(SafeIllustration)),
    );
    expect(
      coverOf('Golpes no WhatsApp').illustration,
      AppIllustration.themeWhatsapp,
    );
    expect(coverOf('Fake News').illustration, AppIllustration.themeFakeNews);
    // Nenhum tema no título: a ilustração genérica de proteção.
    expect(
      coverOf('Golpes Digitais').illustration,
      AppIllustration.themeGeneric,
    );
    expect(tester.takeException(), isNull);
  });

  group('layout (FR-003a)', () {
    testWidgets('letra 100%: uma coluna de cartões grandes (Figma, quadro '
        '06), descrição em até 3 linhas', (tester) async {
      await open(tester);

      final Rect m1 = tester.getRect(card('Golpes Digitais'));
      final Rect m2 = tester.getRect(card('Golpes no WhatsApp'));
      final Rect m3 = tester.getRect(card('Fake News'));
      expect(m2.left, m1.left);
      expect(m2.top, greaterThan(m1.bottom));
      expect(m3.top, greaterThan(m2.bottom));
      expect(m3.width, closeTo(m1.width, 0.5));
      final Text description = tester.widget(
        find.text('Aprenda a reconhecer as táticas mais comuns.'),
      );
      expect(description.maxLines, 3);
    });

    testWidgets('letra 115%: uma coluna, descrição inteira', (tester) async {
      await open(tester, textScale: 1.15);

      final Rect m1 = tester.getRect(card('Golpes Digitais'));
      // Lida antes de rolar: com a letra maior, o 1º cartão sai da tela.
      final Text description = tester.widget(
        find.text('Aprenda a reconhecer as táticas mais comuns.'),
      );
      expect(description.maxLines, isNull);
      await reveal(tester, card('Golpes no WhatsApp'));
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

    testWidgets('a pilha trocada por go (login pelo aviso, specs/020) não '
        'trava os próximos toques', (tester) async {
      await session.logout();
      await session.startGuestSession();
      await open(tester);
      await tester.tap(find.text('Golpes Digitais'));
      await tester.pumpAndSettle();

      // O aviso abre o login sobre as perguntas; a pessoa cria a conta e o
      // login faz go para Atividades.
      unawaited(router.push('/login'));
      await tester.pumpAndSettle();
      final int loadsBefore = repository.calls;
      await session.saveSession(
        accessToken: 'tk2',
        refreshToken: 'rf2',
        email: 'nova@exemplo.com',
        newAccount: true,
      );
      router.go('/activities');
      await tester.pumpAndSettle();
      expect(repository.calls, greaterThan(loadsBefore));

      await tester.tap(find.text('Golpes no WhatsApp'));
      await tester.pumpAndSettle();

      expect(find.text('page:/activities/m2'), findsOneWidget);
    });

    testWidgets('a sessão que expira não recarrega na hora (revisão do PR)', (
      tester,
    ) async {
      await open(tester);
      final int loadsBefore = repository.calls;

      await session.expire();
      await tester.pumpAndSettle();

      expect(repository.calls, loadsBefore);
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

      expect(
        find.byWidgetPredicate((w) => w is SafeSkeleton && w.enabled),
        findsNothing,
      );
      await tester.pumpAndSettle();
      expect(find.text('1 de 9 lições concluídas'), findsOneWidget);
    });

    // Validação da usuária (specs/024): a cada volta, o progresso enche de
    // novo, de 0 até o valor atual.
    testWidgets('voltar à aba enche o progresso de novo', (tester) async {
      await open(tester);
      final Finder ring = find.byType(SafeProgressRing);
      final Element before = tester.element(ring);

      await tester.tap(find.text('Golpes Digitais'));
      await tester.pumpAndSettle();
      router.pop();
      await tester.pump();
      await tester.pump();

      expect(tester.element(ring), isNot(same(before)));
      final double start = tester
          .widget<TweenAnimationBuilder<double>>(
            find.descendant(
              of: ring,
              matching: find.byType(TweenAnimationBuilder<double>),
            ),
          )
          .tween
          .begin!;
      expect(start, 0);
      await tester.pumpAndSettle();
    });
  });

  group('visitante (US3)', () {
    const String notice = 'Sem conta, seu progresso vale até fechar o app.';

    testWidgets('aviso e "Entrar ou criar conta" → login', (tester) async {
      await session.startGuestSession();
      await open(tester);

      expect(find.text(notice), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(notice)).dy,
        lessThan(tester.getTopLeft(card('Golpes Digitais')).dy),
      );

      await tester.tap(find.text('Entrar ou criar conta'));
      await tester.pumpAndSettle();

      expect(find.text('page:/login'), findsOneWidget);
    });

    testWidgets('com conta, sem aviso', (tester) async {
      await open(tester);

      expect(find.text(notice), findsNothing);
    });

    testWidgets('sessão expira: recarrega sem erro e sem aviso', (
      tester,
    ) async {
      repository = FakeActivitiesRepository([
        Right(dashboard()),
        Right(dashboard(totalLessonsCompleted: 0)),
      ]);
      await open(tester);

      await session.expire();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Golpes Digitais'));
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      expect(find.text(notice), findsNothing);
      expect(card('Golpes Digitais'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('respostas da sessão aparecem no painel', (tester) async {
      await session.startGuestSession();
      final store = GuestProgressStore(session);
      addTearDown(store.dispose);
      store
        ..recordAnswer(
          moduleId: 'm1',
          lessonId: 'l1',
          selectedOptionId: 'o1',
          isCorrect: true,
        )
        ..recordAnswer(
          moduleId: 'm1',
          lessonId: 'l2',
          selectedOptionId: 'o2',
          isCorrect: true,
        );
      final remote = FakeActivitiesRemoteDataSource();
      GetIt.instance.registerSingleton<ActivitiesRepository>(
        ActivitiesRepositoryImpl(remote, store, session),
      );
      await open(tester, realRepository: true);

      expect(
        find.descendant(
          of: card('Golpes Digitais'),
          matching: find.text('2 de 3 lições'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card('Golpes Digitais'),
          matching: find.text('Em andamento'),
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('cadastro com o painel aberto: as respostas do visitante vão '
      'antes de recarregar (specs/020, achado no aparelho)', (tester) async {
    await session.logout();
    await session.startGuestSession();
    final FakeActivitiesRemoteDataSource remote =
        FakeActivitiesRemoteDataSource();
    GuestProgressStore? store;
    addTearDown(() => store?.dispose());
    // Como no app: o registro do visitante nasce quando o painel monta a
    // lista, depois de o painel começar a ouvir a sessão.
    GetIt.instance.registerFactory(() {
      store ??= GuestProgressStore(session);
      return ActivitiesDashboardController(
        getDashboard: GetActivitiesDashboardUseCase(
          ActivitiesRepositoryImpl(remote, store!, session),
        ),
      );
    });
    await pumpLocalized(
      tester,
      router: router,
      providers: [fakeNotificationsProvider()],
    );
    store!
      ..recordAnswer(
        moduleId: 'm1',
        lessonId: 'l1',
        selectedOptionId: 'o1',
        isCorrect: true,
      )
      ..recordAnswer(
        moduleId: 'm1',
        lessonId: 'l2',
        selectedOptionId: 'o5',
        isCorrect: false,
      );
    remote.calls.clear();

    await session.saveSession(
      accessToken: 'tk2',
      refreshToken: 'rf2',
      email: 'nova@exemplo.com',
      newAccount: true,
    );
    await tester.pumpAndSettle();

    expect(remote.calls.where((c) => c == 'answer'), hasLength(2));
    expect(remote.calls.last, 'modules');
    expect(
      remote.calls.lastIndexOf('answer'),
      lessThan(remote.calls.lastIndexOf('modules')),
    );
    expect(remote.calls.indexOf('modules'), greaterThan(1));
  });

  group('estados (US4)', () {
    // Sem o aviso de servidor acordando (validação da usuária, specs/024).
    testWidgets('carregando: só o esqueleto, sem aviso de servidor', (
      tester,
    ) async {
      repository = FakeActivitiesRepository()..gate = Completer<void>();
      await open(tester, settle: false);

      expect(
        find.byWidgetPredicate((w) => w is SafeSkeleton && w.enabled),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Carregando'), findsOneWidget);
      // Só o cinza do esqueleto: as capas não mostram a ilustração
      // (validação da usuária, specs/024).
      for (final Element cover in find.byType(SafeIllustration).evaluate()) {
        expect(
          find.ancestor(
            of: find.byElementPredicate((e) => e == cover),
            matching: find.byWidgetPredicate((w) => w is Skeleton),
          ),
          findsWidgets,
        );
      }
      await tester.pump(const Duration(seconds: 6));
      expect(find.textContaining('O serviço está acordando'), findsNothing);

      repository.gate!.complete();
      await tester.pumpAndSettle();
      expect(card('Golpes Digitais'), findsOneWidget);
    });

    Finder illustration(AppIllustration which) => find.byWidgetPredicate(
      (w) => w is SafeIllustration && w.illustration == which,
    );

    // Padrão de sem internet (specs/027 FR-003): a nuvem e a frase padrão.
    testWidgets('sem internet: nuvem, frase padrão e "Tentar novamente", que '
        'recarrega', (tester) async {
      repository = FakeActivitiesRepository([
        const Left(ConnectionFailure()),
        Right(dashboard()),
      ]);
      await open(tester);

      expect(illustration(AppIllustration.stateOffline), findsOneWidget);
      expect(
        find.text('Sem conexão com a internet. Verifique sua rede.'),
        findsOneWidget,
      );
      expect(
        find.text('Não foi possível carregar as atividades'),
        findsNothing,
      );
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(card('Golpes Digitais'), findsOneWidget);
    });

    testWidgets('erro do servidor: tomada e o texto das atividades', (
      tester,
    ) async {
      repository = FakeActivitiesRepository([
        const Left(ServerFailure()),
        Right(dashboard()),
      ]);
      await open(tester);

      expect(illustration(AppIllustration.stateError), findsOneWidget);
      expect(
        find.text('Não foi possível carregar as atividades'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(card('Golpes Digitais'), findsOneWidget);
    });

    testWidgets('sem módulos: mensagem e sem progresso geral', (tester) async {
      repository = FakeActivitiesRepository([
        Right(dashboard(modules: [], totalLessonsAvailable: 0)),
      ]);
      await open(tester);

      expect(find.textContaining('Ainda não há atividades'), findsOneWidget);
      expect(
        find.textContaining('Volte mais tarde para aprender'),
        findsOneWidget,
      );
      expect(find.text('Seu progresso'), findsNothing);
    });

    testWidgets('visitante vê o aviso também no erro', (tester) async {
      await session.startGuestSession();
      repository = FakeActivitiesRepository([const Left(ServerFailure())]);
      await open(tester);

      expect(
        find.text('Sem conta, seu progresso vale até fechar o app.'),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('recarga que falha ao voltar mantém os cartões', (
      tester,
    ) async {
      repository = FakeActivitiesRepository([
        Right(dashboard()),
        const Left(ConnectionFailure()),
      ]);
      await open(tester);

      await tester.tap(find.text('Golpes Digitais'));
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      expect(card('Golpes Digitais'), findsOneWidget);
      expect(
        find.text('Não foi possível carregar as atividades'),
        findsNothing,
      );
    });
  });

  testWidgets('em inglês', (tester) async {
    await open(tester, locale: const Locale('en', 'US'));

    expect(find.text('Your progress'), findsOneWidget);
    expect(find.text('4 of 9 lessons completed'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
  });
}

/// A pontuação vem do detalhe, no repositório (a lista não a traz): aqui ela
/// entra direto no módulo único do painel, de 3 lições.
ActivitiesDashboardEntity _scored(
  ActivitiesDashboardEntity value, {
  required int score,
}) => ActivitiesDashboardEntity(
  modules: [
    value.modules.single.withScore(ModuleScoreEntity(score: score, total: 3)),
  ],
  totalCompleted: value.totalCompleted,
  totalAvailable: value.totalAvailable,
);
