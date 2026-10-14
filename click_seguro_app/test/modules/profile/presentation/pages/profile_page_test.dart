import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/news_counts_entity.dart';
import 'package:click_seguro_app/modules/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../helpers/localized_app.dart';
import '../../../../helpers/profile_dependencies.dart';
import '../../fakes/fake_profile_repository.dart';

void main() {
  late UserSessionService session;
  late FakeProfileRepository repository;
  late GoRouter router;

  const pushedPaths = [
    '/settings',
    '/news/saved',
    '/news/read',
    '/news/liked',
    '/login',
  ];

  Widget placeholder(String path) =>
      Scaffold(appBar: AppBar(), body: Text('page:$path'));

  /// Perfil dentro de um shell de abas, como no app: a aba fica viva ao
  /// trocar de aba.
  GoRouter buildRouter() {
    final rootKey = GlobalKey<NavigatorState>();
    GoRoute tab(String path) =>
        GoRoute(path: path, builder: (_, _) => placeholder(path));
    return GoRouter(
      navigatorKey: rootKey,
      initialLocation: '/profile',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => shell,
          branches: [
            StatefulShellBranch(routes: [tab('/home')]),
            StatefulShellBranch(routes: [tab('/activities')]),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (_, _) => const ProfilePage(),
                  routes: [
                    for (final child in ['edit', 'achievements'])
                      GoRoute(
                        path: child,
                        parentNavigatorKey: rootKey,
                        builder: (_, _) => placeholder('/profile/$child'),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
        for (final path in pushedPaths)
          GoRoute(path: path, builder: (_, _) => placeholder(path)),
      ],
    );
  }

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    repository = registerProfileDependencies(GetIt.instance);
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'maria@exemplo.com',
      userName: 'Maria da Silva',
    );
    router = buildRouter();
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> open(WidgetTester tester) =>
      pumpLocalized(tester, router: router);

  /// Rola a aba até [finder] (a lista só monta o que está perto da tela).
  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  void expectPage(String path) =>
      expect(find.text('page:$path'), findsOneWidget);

  group('visitante', () {
    setUp(() => session.startGuestSession());

    testWidgets('vê o convite e nenhum pedido sai', (tester) async {
      await open(tester);

      expect(find.text('Entre na sua conta'), findsOneWidget);
      for (final benefit in [
        'Guardar seu progresso nas atividades',
        'Salvar notícias para ler depois',
        'Receber alertas de golpes novos',
        'Ganhar conquistas enquanto aprende',
      ]) {
        expect(find.text(benefit), findsOneWidget);
      }
      expect(repository.totalCalls, 0);
    });

    testWidgets('"Entrar ou criar conta" leva ao login', (tester) async {
      await open(tester);

      await tapAndSettle(tester, find.text('Entrar ou criar conta'));

      expectPage('/login');
    });
  });

  group('com conta', () {
    testWidgets('cartão com iniciais e nome, sem o e-mail', (tester) async {
      await open(tester);

      expect(find.text('MS'), findsOneWidget);
      expect(find.text('Maria da Silva'), findsOneWidget);
      expect(find.text('maria@exemplo.com'), findsNothing);
    });

    testWidgets('lápis "Editar perfil" com 48×48 abre a edição', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await open(tester);

      final pencil = find.bySemanticsLabel('Editar perfil');
      expect(pencil, findsOneWidget);
      final Size size = tester.getSize(pencil);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));

      await tapAndSettle(tester, pencil);
      expectPage('/profile/edit');
      semantics.dispose();
    });

    testWidgets('números com rótulos e listas', (tester) async {
      final semantics = tester.ensureSemantics();
      await open(tester);

      for (final text in ['12', '5', '9', 'Lidas', 'Salvas', 'Curtidas']) {
        expect(find.text(text), findsOneWidget);
      }
      for (final (label, path) in [
        ('12 notícias lidas, abrir lista', '/news/read'),
        ('5 notícias salvas, abrir lista', '/news/saved'),
        ('9 notícias curtidas, abrir lista', '/news/liked'),
      ]) {
        await tapAndSettle(tester, find.bySemanticsLabel(label));
        expectPage(path);
        router.pop();
        await tester.pumpAndSettle();
      }
      semantics.dispose();
    });

    testWidgets('conquistas: total, ordem e "Ver todas"', (tester) async {
      await open(tester);

      // 12 lidas: Leitor atento e Leitor dedicado alcançadas.
      expect(find.text('Conquistas (2)'), findsOneWidget);
      expect(find.text('Conquistada'), findsNWidgets(2));
      expect(
        tester.getTopLeft(find.text('Leitor dedicado')).dx,
        lessThan(tester.getTopLeft(find.text('Primeira lição')).dx),
      );
      expect(find.text('0 de 1 lições'), findsOneWidget);

      await tapAndSettle(tester, find.text('Ver todas'));
      expectPage('/profile/achievements');
    });

    testWidgets('atalhos e engrenagem', (tester) async {
      await open(tester);

      await tapAndSettle(tester, find.text('Ler mais notícias'));
      expectPage('/home');

      router.go('/profile');
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('Fazer novas atividades'));
      expectPage('/activities');

      router.go('/profile');
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.byTooltip('Configurações'));
      expectPage('/settings');
    });

    testWidgets('perfil com erro → estado de erro e tentar de novo', (
      tester,
    ) async {
      repository.profileResults
        ..[0] = const Left(ConnectionFailure())
        ..add(const Right(testProfile));
      await open(tester);

      expect(find.byType(SafeErrorState), findsOneWidget);

      await tapAndSettle(tester, find.text('Tentar novamente'));

      expect(find.text('Maria da Silva'), findsOneWidget);
    });

    testWidgets('só os números com erro → aviso no lugar e cartão visível', (
      tester,
    ) async {
      repository.countsResults
        ..[0] = const Left(ServerFailure())
        ..add(const Right(testCounts));
      await open(tester);

      expect(find.text('Maria da Silva'), findsOneWidget);
      expect(
        find.text('Não foi possível carregar seus números.'),
        findsOneWidget,
      );

      await tapAndSettle(tester, find.text('Tentar novamente').first);

      expect(
        find.text('Não foi possível carregar seus números.'),
        findsNothing,
      );
      expect(find.text('Lidas'), findsOneWidget);
    });

    testWidgets('voltar de uma lista atualiza os números', (tester) async {
      final semantics = tester.ensureSemantics();
      await open(tester);
      final int before = repository.countsCalls;
      repository.countsResults[0] = const Right(
        NewsCountsEntity(read: 13, saved: 5, liked: 9),
      );

      await tapAndSettle(
        tester,
        find.bySemanticsLabel('12 notícias lidas, abrir lista'),
      );
      router.pop();
      await tester.pumpAndSettle();

      expect(repository.countsCalls, before + 1);
      expect(find.text('13'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('trocar de aba e voltar atualiza sem mostrar carregando', (
      tester,
    ) async {
      await open(tester);
      final int before = repository.countsCalls;

      router.go('/home');
      await tester.pumpAndSettle();
      router.go('/profile');
      await tester.pump();

      expect(find.byType(SafeLoadingState), findsNothing);
      await tester.pumpAndSettle();
      expect(repository.countsCalls, before + 1);
    });

    testWidgets('fonte 2× num celular: sem estouro', (tester) async {
      tester.view
        ..physicalSize = const Size(1080, 2340)
        ..devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await open(tester);
      await tester.scrollUntilVisible(
        find.text('Fazer novas atividades'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
