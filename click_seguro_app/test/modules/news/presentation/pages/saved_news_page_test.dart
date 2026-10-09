import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/safe_offline_banner.dart';
import 'package:click_seguro_app/core/widgets/slow_request_notice.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/saved_news_result.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/saved_news_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/pages/saved_news_page.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_card.dart';
import 'package:click_seguro_app/modules/shell/presentation/widgets/account_required_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_news_repository.dart';
import '../../fakes/saved_news_controller_factory.dart';

void main() {
  late UserSessionService session;
  late FakeNewsRepository repository;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    await session.startGuestSession();
    repository = FakeNewsRepository();
  });

  tearDown(() async => GetIt.instance.reset());

  Future<void> signIn() => session.saveSession(
    accessToken: 'tk',
    refreshToken: 'rf',
    email: 'ana@test.com',
    userName: 'Ana',
  );

  Right<Failure, SavedNewsResult> pageOf(
    int count, {
    int start = 1,
    int page = 1,
    bool hasMore = false,
    bool isFromCache = false,
  }) => Right(
    SavedNewsResult(
      page: NewsPageEntity(
        items: newsItems(count, start: start),
        hasMore: hasMore,
        page: page,
      ),
      isFromCache: isFromCache,
    ),
  );

  GoRouter buildRouter() => GoRouter(
    initialLocation: '/news/saved',
    routes: [
      GoRoute(
        path: '/news/saved',
        builder: (_, _) => ChangeNotifierProvider<SavedNewsController>(
          create: (_) => buildSavedNewsController(repository),
          child: const SavedNewsPage(),
        ),
      ),
      GoRoute(
        path: '/news/:id',
        builder: (_, state) => Scaffold(
          appBar: AppBar(),
          body: Text('detalhe ${state.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('login')),
      ),
    ],
  );

  /// Com [settle] falso, não espera o carregando (que anima sem fim).
  Future<void> pumpPage(
    WidgetTester tester, {
    bool settle = true,
    Size size = const Size(800, 1600),
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpLocalized(
      tester,
      router: buildRouter(),
      settle: settle,
      theme: theme,
    );
    if (!settle) await tester.pump();
  }

  SavedNewsController controllerOf(WidgetTester tester) =>
      tester.element(find.byType(SavedNewsPage)).read<SavedNewsController>();

  group('com conta', () {
    setUp(signIn);

    testWidgets('barra com "Notícias salvas" e voltar', (tester) async {
      repository.savedResults.add(pageOf(1));

      await pumpPage(tester);

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Notícias salvas'), findsOneWidget);
    });

    testWidgets('cartões do feed na ordem do serviço', (tester) async {
      repository.savedResults.add(pageOf(3));

      await pumpPage(tester);

      expect(find.text('Notícia n1'), findsOneWidget);
      expect(find.text('Folha de Teste · 20 de set.'), findsNWidgets(3));
      final double first = tester.getTopLeft(find.text('Notícia n1')).dy;
      final double second = tester.getTopLeft(find.text('Notícia n2')).dy;
      final double third = tester.getTopLeft(find.text('Notícia n3')).dy;
      expect(first, lessThan(second));
      expect(second, lessThan(third));
      expect(repository.savedCalls, [1]);
    });

    testWidgets('perto do fim carrega a próxima página, sem repetir', (
      tester,
    ) async {
      repository.savedResults
        ..add(pageOf(20, hasMore: true))
        ..add(pageOf(5, start: 18, page: 2));
      await pumpPage(tester);
      expect(repository.savedCalls, [1]);

      await tester.drag(find.byType(ListView), const Offset(0, -6000));
      await tester.pumpAndSettle();

      expect(repository.savedCalls, [1, 2]);
      expect(controllerOf(tester).items, hasLength(22));
    });

    testWidgets('tocar num cartão abre o detalhe e, ao voltar, atualiza a '
        'lista', (tester) async {
      repository.savedResults
        ..add(pageOf(3))
        ..add(pageOf(2, start: 2));
      await pumpPage(tester);

      await tester.tap(find.text('Notícia n1'));
      await tester.pumpAndSettle();
      expect(find.text('detalhe n1'), findsOneWidget);
      expect(repository.savedCalls, [1]);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(repository.savedCalls, [1, 1]);
      expect(find.text('Notícia n1'), findsNothing);
      expect(find.text('Notícia n2'), findsOneWidget);
    });

    testWidgets('lista vazia: mensagem e dica', (tester) async {
      repository.savedResults.add(pageOf(0));

      await pumpPage(tester);

      expect(
        find.text('Você ainda não salvou nenhuma notícia.'),
        findsOneWidget,
      );
      expect(
        find.text('Toque no marcador de uma notícia para guardá-la aqui.'),
        findsOneWidget,
      );
    });

    testWidgets('cópia do aparelho: aviso de offline e a lista', (
      tester,
    ) async {
      repository.savedResults.add(pageOf(2, isFromCache: true));

      await pumpPage(tester);

      expect(find.byType(SafeOfflineBanner), findsOneWidget);
      expect(find.text('Notícia n1'), findsOneWidget);
    });

    testWidgets('erro sem cópia: "Tentar novamente" recarrega', (tester) async {
      repository.savedResults
        ..add(const Left(ConnectionFailure()))
        ..add(pageOf(2));
      await pumpPage(tester);
      expect(find.text('Tentar novamente'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Notícia n1'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsNothing);
    });

    testWidgets('carregando mostra o aviso de servidor lento', (tester) async {
      repository.savedGate = Completer<void>();
      repository.savedResults.add(pageOf(1));
      const slow = 'Conectando ao servidor. Isso pode levar até um minuto.';

      await pumpPage(tester, settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(slow), findsNothing);
      await tester.pump(SlowRequestNotice.delay);
      expect(find.text(slow), findsOneWidget);

      repository.savedGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Notícia n1'), findsOneWidget);
    });
  });

  group('visitante', () {
    testWidgets('convite no lugar da lista, sem pedido e sem lista', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('Entre na sua conta'), findsOneWidget);
      expect(
        find.text('Entre na sua conta para ver as notícias que você salvou.'),
        findsOneWidget,
      );
      expect(find.text('Entrar ou criar conta'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(AccountRequiredSheet), findsNothing);
      expect(repository.savedCalls, isEmpty);
    });

    testWidgets('o botão grande leva ao login, sem janela', (tester) async {
      await pumpPage(tester);
      final size = tester.getSize(find.byKey(SavedNewsPage.loginKey));
      expect(size.height, greaterThanOrEqualTo(48));

      await tester.tap(find.byKey(SavedNewsPage.loginKey));
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
      expect(find.byType(AccountRequiredSheet), findsNothing);
      expect(repository.savedCalls, isEmpty);
    });

    testWidgets('ao entrar na conta com a tela aberta, carrega a lista', (
      tester,
    ) async {
      repository.savedResults.add(pageOf(2));
      await pumpPage(tester);
      expect(repository.savedCalls, isEmpty);

      await signIn();
      await tester.pumpAndSettle();

      expect(find.text('Notícia n1'), findsOneWidget);
      expect(repository.savedCalls, [1]);
    });
  });

  group('acessibilidade (FR-022, SC-008)', () {
    void useScale2x(WidgetTester tester) {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }

    testWidgets('com conta: cartões com 48 dp ou mais e leitura na ordem', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await signIn();
      repository.savedResults.add(pageOf(3));
      await pumpPage(tester);

      final cards = find.byType(NewsCard);
      expect(cards, findsNWidgets(3));
      for (var i = 0; i < 3; i++) {
        expect(tester.getSize(cards.at(i)).height, greaterThanOrEqualTo(48));
      }
      final tops = [
        for (final n in ['n1', 'n2', 'n3'])
          tester.getTopLeft(find.bySemanticsLabel(RegExp('^Notícia $n, '))).dy,
      ];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(tops.toSet(), hasLength(3));
      handle.dispose();
    });

    testWidgets('fonte 2×: lista e convite sem sobreposição', (tester) async {
      useScale2x(tester);
      await signIn();
      repository.savedResults.add(pageOf(3, isFromCache: true));
      await pumpPage(tester, size: const Size(360, 800));

      final context = tester.element(find.byType(SavedNewsPage));
      expect(MediaQuery.textScalerOf(context).scale(10), 20);
      expect(tester.takeException(), isNull);
      final first = tester.getRect(find.byType(NewsCard).first);
      expect(first.left, greaterThanOrEqualTo(0));
      expect(first.right, lessThanOrEqualTo(360));
    });

    testWidgets('fonte 2×: convite do visitante, botão grande inteiro', (
      tester,
    ) async {
      useScale2x(tester);
      await pumpPage(tester, size: const Size(360, 800));

      expect(tester.takeException(), isNull);
      final rect = tester.getRect(find.byKey(SavedNewsPage.loginKey));
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(360));
    });

    testWidgets('fonte 2×: lista vazia sem estouro', (tester) async {
      useScale2x(tester);
      await signIn();
      repository.savedResults.add(pageOf(0));
      await pumpPage(tester, size: const Size(360, 800));

      expect(tester.takeException(), isNull);
      expect(
        find.text('Você ainda não salvou nenhuma notícia.'),
        findsOneWidget,
      );
    });

    testWidgets('alto contraste: paleta da feature 009 na lista e no '
        'convite', (tester) async {
      await signIn();
      repository.savedResults.add(pageOf(2));
      await pumpPage(tester, theme: AppTheme.highContrastTheme);

      final context = tester.element(find.byType(SavedNewsPage));
      expect(context.colors, AppPalette.highContrast);
      expect(find.byType(NewsCard), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });
}
