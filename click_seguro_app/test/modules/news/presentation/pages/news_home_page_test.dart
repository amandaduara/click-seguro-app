import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_loading_state.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/feed_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/pages/news_home_page.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/category_filter_bar.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_news_repository.dart';
import '../../fakes/feed_controller_factory.dart';

void main() {
  late UserSessionService session;
  late FakeNewsRepository repository;
  late GoRouter router;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    await session.startGuestSession();
    repository = FakeNewsRepository();
    router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const NewsHomePage()),
        GoRoute(
          path: '/news/:id',
          builder: (_, state) =>
              Scaffold(body: Text('detalhe ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/reels',
          builder: (_, state) => Scaffold(
            body: Text('reels ${state.uri.queryParameters['start']}'),
          ),
        ),
      ],
    );
  });

  tearDown(() => GetIt.instance.reset());

  /// Carrega o feed antes de montar a página: o carregando anima sem fim.
  /// A tela é alta para que as seções e a lista caibam sem rolar.
  Future<FeedController> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = buildFeedController(repository);
    await controller.load();
    await pumpLocalized(
      tester,
      router: router,
      providers: [
        ChangeNotifierProvider<FeedController>.value(value: controller),
      ],
    );
    return controller;
  }

  Finder textInScroll(String text) => find.descendant(
    of: find.byType(CustomScrollView),
    matching: find.text(text),
  );

  group('feed', () {
    testWidgets('carregando mostra o indicador e o aviso de servidor lento', (
      tester,
    ) async {
      repository.feedGate = Completer<void>();
      final controller = buildFeedController(repository);
      unawaited(controller.load());
      await pumpLocalized(
        tester,
        router: router,
        providers: [
          ChangeNotifierProvider<FeedController>.value(value: controller),
        ],
        settle: false,
      );

      expect(find.byType(SafeLoadingState), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(
        find.text('Conectando ao servidor. Isso pode levar até um minuto.'),
        findsOneWidget,
      );

      repository.feedGate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('seções na ordem e recomendadas só quando houver', (
      tester,
    ) async {
      repository.feedResults[0] = Right(
        newsFeed(
          highlights: [newsItem('h1')],
          recent: newsItems(2),
          reels: [newsItem('reel1')],
        ),
      );

      await pumpPage(tester);

      expect(find.text('Notícias seguras'), findsOneWidget);
      final novidades = tester.getTopLeft(textInScroll('Novidades')).dy;
      final destaques = tester.getTopLeft(textInScroll('Destaques')).dy;
      final recentes = tester.getTopLeft(textInScroll('Tudo recente')).dy;
      expect(novidades, lessThan(destaques));
      expect(destaques, lessThan(recentes));
      expect(textInScroll('Recomendadas para você'), findsNothing);
    });

    testWidgets('recomendadas aparecem quando vêm preenchidas', (tester) async {
      repository.feedResults[0] = Right(
        newsFeed(recommended: [newsItem('r1')]),
      );

      await pumpPage(tester);

      expect(textInScroll('Recomendadas para você'), findsOneWidget);
    });

    testWidgets('sem Reels, sem "Novidades"', (tester) async {
      await pumpPage(tester);

      expect(textInScroll('Novidades'), findsNothing);
    });

    group('subtítulo', () {
      testWidgets('visitante sem novas', (tester) async {
        await pumpPage(tester);

        expect(find.text('Bem-vindo!'), findsOneWidget);
      });

      testWidgets('visitante com 3 novas', (tester) async {
        repository.feedResults[0] = Right(
          newsFeed(
            recent: [
              for (final id in ['a', 'b', 'c'])
                newsItem(id, originalPublishedAt: DateTime(2026, 10, 5, 9)),
            ],
          ),
        );

        await pumpPage(tester);

        expect(
          find.text('Bem-vindo! 3 notícias novas para você'),
          findsOneWidget,
        );
      });

      testWidgets('conectada com 1 nova', (tester) async {
        await session.saveSession(
          accessToken: 'acesso-1',
          refreshToken: 'renovacao-1',
          email: 'maria@exemplo.com',
          userName: 'Maria',
        );
        repository.feedResults[0] = Right(
          newsFeed(
            recent: [
              newsItem('a', originalPublishedAt: DateTime(2026, 10, 5, 9)),
            ],
          ),
        );

        await pumpPage(tester);

        expect(
          find.text('Olá, Maria! 1 notícia nova para você'),
          findsOneWidget,
        );
      });
    });

    testWidgets('cartão abre o detalhe; Novidades abre os Reels', (
      tester,
    ) async {
      repository.feedResults[0] = Right(
        newsFeed(recent: newsItems(1), reels: [newsItem('reel1')]),
      );
      await pumpPage(tester);

      await tester.tap(find.byType(NewsCard).first);
      await tester.pumpAndSettle();
      expect(find.text('detalhe n1'), findsOneWidget);

      router.go('/home');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('Notícia reel1')));
      await tester.pumpAndSettle();
      expect(find.text('reels reel1'), findsOneWidget);
    });

    testWidgets('chega ao fim: carrega mais e depois avisa o fim', (
      tester,
    ) async {
      repository.feedResults[0] = Right(
        newsFeed(recent: newsItems(3), hasMore: true),
      );
      repository.feedPages[2] = Right(
        NewsPageEntity(items: newsItems(2, start: 4), hasMore: false, page: 2),
      );

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(repository.feedPageCalls, [2]);
      expect(find.text('Notícia n5'), findsOneWidget);
      expect(find.text('Você viu todas as notícias'), findsOneWidget);
    });

    testWidgets('falha ao carregar mais mostra "Tentar novamente"', (
      tester,
    ) async {
      repository.feedResults[0] = Right(
        newsFeed(recent: newsItems(3), hasMore: true),
      );
      repository.feedPages[2] = const Left(ConnectionFailure());

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível carregar mais.'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('erro sem cópia e tentar de novo', (tester) async {
      repository.feedResults
        ..clear()
        ..addAll([const Left(ConnectionFailure()), Right(newsFeed())]);

      await pumpPage(tester);

      expect(find.byType(SafeErrorState), findsOneWidget);
      expect(
        find.text('Sem conexão com a internet. Verifique sua rede.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(find.byType(NewsCard), findsWidgets);
    });

    testWidgets('puxar para baixo recarrega', (tester) async {
      await pumpPage(tester);

      // Arraste em passos, como um dedo, a partir do topo da lista; o
      // indicador só arma depois de ~25% da altura da tela.
      final gesture = await tester.startGesture(
        tester.getTopLeft(find.byType(CustomScrollView)) + const Offset(20, 20),
      );
      for (var i = 0; i < 40; i++) {
        await gesture.moveBy(const Offset(0, 40));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(repository.feedCalls, 2);
    });
  });

  group('categoria', () {
    // O nome da categoria também aparece nos cartões: toca no chip da barra.
    Finder chip(String label) => find.descendant(
      of: find.byType(CategoryFilterBar),
      matching: find.text(label),
    );

    testWidgets('tocar numa categoria mostra só a lista dela', (tester) async {
      repository.feedResults[0] = Right(
        newsFeed(highlights: [newsItem('h1')], reels: [newsItem('reel1')]),
      );
      repository.newsResults[0] = Right(
        NewsPageEntity(items: [newsItem('p1')], hasMore: false, page: 1),
      );
      await pumpPage(tester);

      await tester.tap(chip('Phishing'));
      await tester.pumpAndSettle();

      expect(find.text('Notícia p1'), findsOneWidget);
      expect(textInScroll('Novidades'), findsNothing);
      expect(textInScroll('Destaques'), findsNothing);
      expect(textInScroll('Tudo recente'), findsOneWidget);
    });

    testWidgets('categoria vazia mostra a mensagem', (tester) async {
      repository.newsResults[0] = const Right(
        NewsPageEntity(items: [], hasMore: false, page: 1),
      );
      await pumpPage(tester);

      await tester.tap(chip('Golpes bancários'));
      await tester.pumpAndSettle();

      expect(
        find.text('Nenhuma notícia nesta categoria ainda.'),
        findsOneWidget,
      );
    });

    testWidgets('"Todas" volta às seções', (tester) async {
      repository.feedResults[0] = Right(newsFeed(highlights: [newsItem('h1')]));
      await pumpPage(tester);
      await tester.tap(chip('Phishing'));
      await tester.pumpAndSettle();

      await tester.tap(chip('Todas'));
      await tester.pumpAndSettle();

      expect(textInScroll('Destaques'), findsOneWidget);
    });

    testWidgets('voltar do detalhe mantém a categoria e a lista', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      repository.newsResults[0] = Right(
        NewsPageEntity(items: [newsItem('p1')], hasMore: false, page: 1),
      );
      await pumpPage(tester);
      await tester.tap(chip('Phishing'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NewsCard));
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      expect(find.text('Notícia p1'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Phishing')),
        isSemantics(isSelected: true),
      );
      expect(repository.newsCalls, hasLength(1));
      semantics.dispose();
    });
  });

  group('busca', () {
    Future<void> search(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    }

    testWidgets('digitar e esperar mostra "Resultados"', (tester) async {
      repository.newsResults[0] = Right(
        NewsPageEntity(items: [newsItem('pix1')], hasMore: false, page: 1),
      );
      await pumpPage(tester);

      await search(tester, 'pix');

      expect(textInScroll('Resultados'), findsOneWidget);
      expect(find.text('Notícia pix1'), findsOneWidget);
    });

    testWidgets('sem resultado mostra a mensagem com o texto', (tester) async {
      repository.newsResults[0] = const Right(
        NewsPageEntity(items: [], hasMore: false, page: 1),
      );
      await pumpPage(tester);

      await search(tester, 'xyzxyz');

      expect(
        find.text(
          'Nenhuma notícia encontrada para "xyzxyz". Tente outras palavras.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('o "X" volta ao feed', (tester) async {
      repository.feedResults[0] = Right(newsFeed(highlights: [newsItem('h1')]));
      await pumpPage(tester);
      await search(tester, 'pix');

      await tester.tap(find.byTooltip('Limpar busca'));
      await tester.pumpAndSettle();

      expect(textInScroll('Destaques'), findsOneWidget);
      expect(textInScroll('Tudo recente'), findsOneWidget);
    });
  });
}
