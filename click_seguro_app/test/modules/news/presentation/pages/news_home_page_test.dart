import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/widgets/listen_button.dart';
import 'package:click_seguro_app/core/widgets/safe_error_state.dart';
import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/feed_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/pages/news_home_page.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/category_filter_bar.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/feed_search_field.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_card.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_cover.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_grid.dart';
import 'package:click_seguro_app/modules/common/services/text_to_speech_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../../fakes/fake_text_to_speech_service.dart';
import '../../../../helpers/localized_app.dart';
import '../../../../helpers/notifications_provider.dart';
import '../../fakes/fake_news_repository.dart';
import '../../fakes/feed_controller_factory.dart';

void main() {
  late UserSessionService session;
  late FakeNewsRepository repository;
  late GoRouter router;
  late FakeTextToSpeechService tts;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    tts = FakeTextToSpeechService();
    final preferences = AccessibilityPreferencesNotifier();
    GetIt.instance
      ..registerSingleton<UserSessionService>(session)
      ..registerSingleton<AccessibilityPreferencesNotifier>(preferences)
      ..registerFactory(
        () => ReadAloudController(tts, preferences: preferences),
      );
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
          // A prévia (`extra`) leva o item tocado (specs/022 FR-019).
          builder: (_, state) => Scaffold(
            body: Text(
              'reels ${state.uri.queryParameters['start']} '
              'prévia ${(state.extra as NewsItemEntity?)?.id}',
            ),
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
        fakeNotificationsProvider(),
      ],
    );
    return controller;
  }

  Finder textInScroll(String text) => find.descendant(
    of: find.byType(CustomScrollView),
    matching: find.text(text),
  );

  group('feed', () {
    // Sem aviso de servidor lento (validação da usuária, specs/024).
    testWidgets('carregando mostra o esqueleto, sem aviso de servidor', (
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
          fakeNotificationsProvider(),
        ],
        settle: false,
      );

      expect(
        find.byWidgetPredicate((w) => w is SafeSkeleton && w.enabled),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pump(const Duration(seconds: 6));
      expect(
        find.text('Conectando ao servidor. Isso pode levar até um minuto.'),
        findsNothing,
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

    // Validação da usuária (specs/024): a saudação e a busca sobem com as
    // notícias; os filtros ficam presos no topo.
    testWidgets('rolando, o cabeçalho sobe e os filtros ficam no topo', (
      tester,
    ) async {
      repository.feedResults[0] = Right(newsFeed(recent: newsItems(20)));
      await pumpPage(tester);
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();
      final double filtersTop = tester
          .getTopLeft(find.byType(CategoryFilterBar))
          .dy;

      await tester.drag(find.byType(NewsCard).first, const Offset(0, -1500));
      await tester.pumpAndSettle();

      expect(find.text('Notícias seguras').hitTestable(), findsNothing);
      expect(find.byType(FeedSearchField).hitTestable(), findsNothing);
      final double pinnedTop = tester
          .getTopLeft(find.byType(CategoryFilterBar))
          .dy;
      expect(pinnedTop, lessThan(filtersTop));
      expect(find.byType(CategoryFilterBar).hitTestable(), findsOneWidget);
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
      expect(find.text('reels reel1 prévia reel1'), findsOneWidget);
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

  // Grade do feed (FR-025, T051). A tela tem 800 de largura e as seções
  // 20 de margem: 760 para os cartões.
  group('ouvir destaques', () {
    Finder listen() => find.byKey(NewsHomePage.highlightsListenKey);

    void withHighlights() => repository.feedResults[0] = Right(
      newsFeed(
        highlights: [newsItem('h1'), newsItem('h2')],
        reels: [newsItem('reel1')],
      ),
    );

    testWidgets('"Ouvir" ao lado do título "Destaques", antes dos cartões', (
      tester,
    ) async {
      withHighlights();
      await pumpPage(tester);

      expect(listen(), findsOneWidget);
      expect(find.text('Ouvir'), findsOneWidget);
      final Rect title = tester.getRect(textInScroll('Destaques'));
      final Rect button = tester.getRect(listen());
      expect(button.left, greaterThan(title.right));
      expect(button.center.dy, closeTo(title.center.dy, 24));
      expect(
        button.bottom,
        lessThan(tester.getTopLeft(find.text('Notícia h1')).dy),
      );
      final Size size = tester.getSize(
        find.descendant(of: listen(), matching: find.byType(InkWell)),
      );
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('lê o título da seção e título e fonte de cada destaque; '
        'de novo, para', (tester) async {
      withHighlights();
      await pumpPage(tester);

      await tester.tap(listen());
      await tester.pump();

      // O título da seção (app) e, depois, cada destaque (conteúdo).
      expect(tts.spoken.single.text, 'Destaques.');
      tts.finishSpeaking();
      await tester.pump();
      expect(tts.spoken.last.text, 'Notícia h1. Folha de Teste.');
      expect(tts.spoken.last.language, SpeechLanguage.ptBr);
      expect(find.text('Parar'), findsOneWidget);

      await tester.tap(listen());
      await tester.pump();
      expect(tts.stopCalls, 1);
      expect(find.text('Ouvir'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('sem destaques, sem botão', (tester) async {
      repository.feedResults[0] = Right(newsFeed(reels: [newsItem('reel1')]));
      await pumpPage(tester);

      expect(listen(), findsNothing);
      expect(find.byType(ListenButton), findsNothing);
    });

    testWidgets('sem voz no idioma, sem botão', (tester) async {
      tts.availableLanguages = {};
      withHighlights();
      await pumpPage(tester);

      expect(textInScroll('Destaques'), findsOneWidget);
      expect(listen(), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('abrir uma notícia para a leitura', (tester) async {
      withHighlights();
      await pumpPage(tester);
      await tester.tap(listen());
      await tester.pump();

      await tester.tap(find.byType(NewsCard).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('detalhe'), findsOneWidget);
      expect(tts.stopCalls, greaterThanOrEqualTo(1));
    });

    testWidgets('trocar para uma categoria (botão some) para a leitura', (
      tester,
    ) async {
      withHighlights();
      repository.newsResults[0] = Right(
        NewsPageEntity(items: [newsItem('p1')], hasMore: false, page: 1),
      );
      await pumpPage(tester);
      await tester.tap(listen());
      await tester.pump();

      await tester.tap(
        find.descendant(
          of: find.byType(CategoryFilterBar),
          matching: find.text('Phishing'),
        ),
      );
      await tester.pumpAndSettle();

      expect(listen(), findsNothing);
      expect(tts.stopCalls, greaterThanOrEqualTo(1));
    });
  });

  group('grade', () {
    const double content = 760;

    Finder cardOf(String id) =>
        find.byWidgetPredicate((w) => w is NewsCard && w.item.id == id);

    Rect rectOf(WidgetTester tester, String id) => tester.getRect(cardOf(id));

    double? coverOf(WidgetTester tester, String id) =>
        tester.widget<NewsCard>(cardOf(id)).coverHeight;

    List<NewsItemEntity> items(String prefix, int count) => [
      for (int i = 1; i <= count; i++) newsItem('$prefix$i'),
    ];

    testWidgets('"Destaques" ocupa a largura toda', (tester) async {
      repository.feedResults[0] = Right(
        newsFeed(highlights: [newsItem('h1')], recent: items('n', 2)),
      );

      await pumpPage(tester);

      expect(rectOf(tester, 'h1').width, closeTo(content, 1));
      expect(tester.widget<NewsCard>(cardOf('h1')).compact, isFalse);
    });

    for (final (section, recommended) in [
      ('"Recomendadas"', true),
      ('"Tudo recente"', false),
    ]) {
      testWidgets('$section em 2 colunas, na ordem da API', (tester) async {
        repository.feedResults[0] = Right(
          newsFeed(
            recommended: recommended ? items('g', 5) : const [],
            recent: recommended ? items('n', 1) : items('g', 5),
          ),
        );

        await pumpPage(tester);

        final List<Rect> rects = [
          for (int i = 1; i <= 5; i++) rectOf(tester, 'g$i'),
        ];
        // Duas colunas: cada cartão com menos da metade da largura.
        for (final rect in rects) {
          expect(rect.width, lessThan(content / 2));
        }
        // Esquerda → direita, de cima para baixo: 1 | 2, 3 | 4, 5 | .
        expect(rects[0].left, lessThan(rects[1].left));
        expect(rects[0].top, rects[1].top);
        for (final i in [2, 4]) {
          expect(rects[i].left, rects[0].left);
          expect(rects[i].top, greaterThan(rects[i - 2].top));
        }
        expect(rects[3].left, rects[1].left);
        expect(rects[3].top, greaterThan(rects[1].top));
      });
    }

    testWidgets('com letra acima de 1,3, uma coluna', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      repository.feedResults[0] = Right(newsFeed(recent: items('n', 3)));

      await pumpPage(tester);

      final List<Rect> rects = [
        for (int i = 1; i <= 3; i++) rectOf(tester, 'n$i'),
      ];
      for (final rect in rects) {
        expect(rect.width, closeTo(content, 1));
      }
      expect(rects[0].top, lessThan(rects[1].top));
      expect(rects[1].top, lessThan(rects[2].top));
      // Capa mais alta na coluna única.
      expect(coverOf(tester, 'n1'), NewsGrid.coverHeights[0] + 40);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a mesma lista dá as mesmas alturas de capa', (tester) async {
      repository.feedResults[0] = Right(
        newsFeed(recommended: items('r', 5), recent: items('n', 5)),
      );

      await pumpPage(tester);

      // Pela posição na lista: as duas seções repetem o mesmo desenho.
      final List<double> expected = [
        for (int i = 0; i < 5; i++) NewsGrid.coverHeightAt(i),
      ];
      expect([for (int i = 1; i <= 5; i++) coverOf(tester, 'r$i')], expected);
      expect([for (int i = 1; i <= 5; i++) coverOf(tester, 'n$i')], expected);
      // Alturas variadas, como no Pinterest.
      expect(expected.toSet().length, greaterThan(1));
      // E a capa desenhada tem essa altura.
      for (final (index, id) in ['r1', 'r2'].indexed) {
        expect(
          tester
              .getSize(
                find.descendant(
                  of: cardOf(id),
                  matching: find.byType(NewsCover),
                ),
              )
              .height,
          expected[index],
        );
      }
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

    // Vindo de "Todas" sem "Últimas", a lista antiga é vazia: enquanto a
    // categoria carrega, o vazio não pode piscar (specs/022, achado da T058).
    testWidgets('trocando de categoria, o vazio não pisca', (tester) async {
      repository.feedResults[0] = Right(
        newsFeed(highlights: [newsItem('h1')], recent: const []),
      );
      repository.newsGate = Completer<void>();
      await pumpPage(tester);

      await tester.tap(chip('Phishing'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Nenhuma notícia nesta categoria ainda.'), findsNothing);
      repository.newsGate!.complete();
      await tester.pumpAndSettle();
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

  group('sem internet', () {
    const offline = 'Você está sem internet. Mostrando o conteúdo salvo.';

    testWidgets('cópia guardada: faixa no topo e aviso no fim', (tester) async {
      repository.feedResults[0] = Right(newsFeed(isFromCache: true));

      await pumpPage(tester);

      expect(find.text(offline), findsOneWidget);
      expect(
        find.text('Conecte-se à internet para ver mais notícias.'),
        findsOneWidget,
      );
      expect(find.text('Você viu todas as notícias'), findsNothing);
    });

    testWidgets('sem conexão e sem cópia: erro com "Tentar novamente"', (
      tester,
    ) async {
      repository.feedResults[0] = const Left(ConnectionFailure());

      await pumpPage(tester);

      expect(
        find.text('Sem conexão com a internet. Verifique sua rede.'),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.text(offline), findsNothing);
    });

    testWidgets('atualizar com sucesso tira a faixa', (tester) async {
      repository.feedResults
        ..clear()
        ..addAll([Right(newsFeed(isFromCache: true)), Right(newsFeed())]);
      final controller = await pumpPage(tester);

      await tester.runAsync(controller.refresh);
      await tester.pumpAndSettle();

      expect(find.text(offline), findsNothing);
    });
  });
}
