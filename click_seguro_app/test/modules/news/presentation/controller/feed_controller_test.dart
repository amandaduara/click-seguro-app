import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/feed_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/feed_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../fakes/fake_news_repository.dart';
import '../../fakes/feed_controller_factory.dart';

void main() {
  late FakeNewsRepository repository;
  late FeedController controller;

  setUp(() {
    repository = FakeNewsRepository();
    controller = buildFeedController(repository);
  });

  tearDown(() => controller.dispose());

  NewsPageEntity page(int number, List<String> ids, {bool hasMore = true}) =>
      NewsPageEntity(
        items: [for (final id in ids) newsItem(id)],
        hasMore: hasMore,
        page: number,
      );

  group('feed', () {
    test('load preenche seções, Reels e lista', () async {
      repository.feedResults[0] = Right(
        newsFeed(
          highlights: [newsItem('h1')],
          recommended: [newsItem('r1')],
          recent: newsItems(20),
          hasMore: true,
          reels: [
            newsItem('reel1', originalPublishedAt: DateTime(2026, 10, 5, 9)),
          ],
        ),
      );
      expect(controller.status, FeedStatus.loading);

      await controller.load();

      expect(controller.status, FeedStatus.loaded);
      expect(controller.highlights.single.id, 'h1');
      expect(controller.recommended.single.id, 'r1');
      expect(controller.reels.single.id, 'reel1');
      expect(controller.items, hasLength(20));
      expect(controller.hasMore, isTrue);
      expect(controller.newCount, 1);
      expect(controller.isFromCache, isFalse);
    });

    test('falha sem cópia → erro; tentar de novo → sucesso', () async {
      repository.feedResults
        ..clear()
        ..addAll([const Left(ConnectionFailure()), Right(newsFeed())]);

      await controller.load();
      expect(controller.status, FeedStatus.error);
      expect(controller.failure, isA<ConnectionFailure>());

      await controller.load();
      expect(controller.status, FeedStatus.loaded);
      expect(controller.failure, isNull);
    });

    test('sessão recusada na carga tenta de novo uma vez sozinha', () async {
      repository.feedResults
        ..clear()
        ..addAll([const Left(UnauthorizedFailure()), Right(newsFeed())]);

      await controller.load();

      expect(repository.feedCalls, 2);
      expect(controller.status, FeedStatus.loaded);
    });

    test('sessão recusada duas vezes → erro', () async {
      repository.feedResults
        ..clear()
        ..add(const Left(UnauthorizedFailure()));

      await controller.load();

      expect(repository.feedCalls, 2);
      expect(controller.status, FeedStatus.error);
    });

    group('mais páginas', () {
      setUp(() async {
        repository.feedResults[0] = Right(
          newsFeed(recent: newsItems(20), hasMore: true),
        );
        await controller.load();
      });

      test('acrescenta só notícias novas', () async {
        repository.feedPages[2] = Right(page(2, ['n20', 'n21', 'n22']));

        await controller.loadMore();

        expect(repository.feedPageCalls, [2]);
        expect(controller.items.map((n) => n.id).skip(19), [
          'n20',
          'n21',
          'n22',
        ]);
        expect(controller.hasMore, isTrue);
      });

      test('página sem nada novo encerra a lista', () async {
        repository.feedPages[2] = Right(page(2, ['n1', 'n2']));

        await controller.loadMore();
        await controller.loadMore();

        expect(controller.hasMore, isFalse);
        expect(repository.feedPageCalls, [2]);
      });

      test('fim do servidor encerra a lista', () async {
        repository.feedPages[2] = Right(page(2, ['n21'], hasMore: false));

        await controller.loadMore();
        await controller.loadMore();

        expect(controller.hasMore, isFalse);
        expect(controller.isEnd, isTrue);
        expect(repository.feedPageCalls, [2]);
      });

      test('duas chamadas seguidas fazem um pedido', () async {
        repository.feedPages[2] = Right(page(2, ['n21']));

        await Future.wait([controller.loadMore(), controller.loadMore()]);

        expect(repository.feedPageCalls, [2]);
      });

      test('falha mantém a lista e permite tentar de novo', () async {
        repository.feedPages[2] = const Left(ConnectionFailure());

        await controller.loadMore();
        expect(controller.items, hasLength(20));
        expect(controller.loadMoreFailure, isA<ConnectionFailure>());

        repository.feedPages[2] = Right(page(2, ['n21']));
        await controller.loadMore();
        expect(controller.loadMoreFailure, isNull);
        expect(controller.items, hasLength(21));
      });

      test('newCount cresce com notícias novas de uma página', () async {
        repository.feedPages[2] = Right(
          NewsPageEntity(
            items: [
              newsItem('novo', originalPublishedAt: DateTime(2026, 10, 5, 7)),
            ],
            hasMore: true,
            page: 2,
          ),
        );
        expect(controller.newCount, 0);

        await controller.loadMore();

        expect(controller.newCount, 1);
      });
    });

    test('newCount não muda com categoria ativa', () async {
      repository.feedResults[0] = Right(
        newsFeed(
          recent: [
            newsItem('a', originalPublishedAt: DateTime(2026, 10, 5, 9)),
          ],
        ),
      );
      await controller.load();
      expect(controller.newCount, 1);

      await controller.selectCategory('phishing');

      expect(controller.newCount, 1);
    });

    test('refresh volta à página 1 e substitui a lista', () async {
      repository.feedResults
        ..clear()
        ..addAll([
          Right(newsFeed(recent: newsItems(2))),
          Right(newsFeed(recent: newsItems(1, start: 50))),
        ]);
      await controller.load();

      await controller.refresh();

      expect(controller.items.single.id, 'n50');
      expect(repository.feedCalls, 2);
    });

    test('resposta antiga de uma carga anterior é descartada', () async {
      final firstGate = repository.feedGate = Completer<void>();
      final first = controller.load();
      repository.feedGate = null;
      repository.feedResults
        ..clear()
        ..add(Right(newsFeed(recent: newsItems(1, start: 90))));

      await controller.load();
      // A 1ª carga responde depois da 2ª: deve ser ignorada.
      firstGate.complete();
      await first;

      expect(controller.items.single.id, 'n90');
    });
  });

  group('categoria', () {
    test('load também carrega as categorias', () async {
      await controller.load();

      expect(repository.categoriesCalls, 1);
      expect(controller.categories.map((c) => c.slug), [
        'phishing',
        'golpes-bancarios',
      ]);
    });

    test('falha nas categorias não afeta o feed', () async {
      repository.categoriesResult = const Left(ConnectionFailure());

      await controller.load();

      expect(controller.categories, isEmpty);
      expect(controller.status, FeedStatus.loaded);
    });

    test('selecionar uma categoria troca para a lista filtrada', () async {
      repository.feedResults[0] = Right(
        newsFeed(highlights: [newsItem('h1')], reels: [newsItem('reel1')]),
      );
      repository.newsResults[0] = Right(page(1, ['p1', 'p2'], hasMore: true));
      await controller.load();

      final selecting = controller.selectCategory('phishing');
      expect(controller.status, FeedStatus.loading);
      await selecting;

      expect(controller.status, FeedStatus.loaded);
      expect(controller.filter.categorySlug, 'phishing');
      expect(repository.newsCalls.single.page, 1);
      expect(repository.newsCalls.single.filter.categorySlug, 'phishing');
      expect(controller.items.map((n) => n.id), ['p1', 'p2']);
      expect(controller.reels, isEmpty);
      expect(controller.highlights, isEmpty);
      expect(controller.recommended, isEmpty);
    });

    test('mais páginas continuam na mesma categoria', () async {
      repository.newsResults
        ..clear()
        ..addAll([
          Right(page(1, ['p1'], hasMore: true)),
          Right(page(2, ['p2'], hasMore: false)),
        ]);
      await controller.load();
      await controller.selectCategory('phishing');

      await controller.loadMore();

      expect(repository.newsCalls.last.page, 2);
      expect(repository.newsCalls.last.filter.categorySlug, 'phishing');
      expect(controller.items.map((n) => n.id), ['p1', 'p2']);
    });

    test('"Todas" volta ao feed', () async {
      await controller.load();
      await controller.selectCategory('phishing');

      await controller.selectCategory(null);

      expect(controller.filter.isEmpty, isTrue);
      expect(repository.feedCalls, 2);
    });

    test('trocas rápidas: vale a última escolha', () async {
      await controller.load();
      repository.newsGate = Completer<void>();
      repository.newsResults
        ..clear()
        ..addAll([
          Right(page(1, ['velha'])),
          Right(page(1, ['nova'])),
        ]);

      final first = controller.selectCategory('phishing');
      final gate = repository.newsGate!;
      repository.newsGate = null;
      await controller.selectCategory('golpes-bancarios');
      gate.complete();
      await first;

      expect(controller.filter.categorySlug, 'golpes-bancarios');
      expect(controller.items.single.id, 'nova');
    });

    test('selecionar a categoria já ativa não faz pedido', () async {
      await controller.load();
      await controller.selectCategory('phishing');

      await controller.selectCategory('phishing');

      expect(repository.newsCalls, hasLength(1));
    });
  });

  // Relógio falso do testWidgets: a espera de 500 ms sem tempo real.
  group('busca', () {
    testWidgets('espera parar de digitar e busca uma vez', (tester) async {
      await controller.load();

      controller.onSearchChanged('p');
      await tester.pump(const Duration(milliseconds: 100));
      controller.onSearchChanged('pi');
      await tester.pump(const Duration(milliseconds: 100));
      controller.onSearchChanged('pix');
      await tester.pump(const Duration(milliseconds: 499));
      expect(repository.newsCalls, isEmpty);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      expect(repository.newsCalls, hasLength(1));
      expect(repository.newsCalls.single.filter.normalizedSearch, 'pix');
      expect(controller.isSearching, isTrue);
    });

    testWidgets('um caractere não busca', (tester) async {
      await controller.load();

      controller.onSearchChanged('p');
      await tester.pump(const Duration(seconds: 1));

      expect(repository.newsCalls, isEmpty);
      expect(controller.isSearching, isFalse);
    });

    testWidgets('busca dentro da categoria ativa', (tester) async {
      await controller.load();
      await controller.selectCategory('phishing');

      controller.onSearchChanged('pix');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      final filter = repository.newsCalls.last.filter;
      expect(filter.categorySlug, 'phishing');
      expect(filter.normalizedSearch, 'pix');
    });

    testWidgets('respostas fora de ordem: vale a última busca', (tester) async {
      await controller.load();
      repository.newsGate = Completer<void>();
      repository.newsResults
        ..clear()
        ..addAll([
          Right(page(1, ['velha'])),
          Right(page(1, ['nova'])),
        ]);

      controller.onSearchChanged('pi');
      await tester.pump(const Duration(milliseconds: 500));
      final gate = repository.newsGate!;
      repository.newsGate = null;
      controller.onSearchChanged('pix');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      gate.complete();
      await tester.pump();

      expect(controller.items.single.id, 'nova');
    });

    testWidgets('limpar volta à lista sem busca na hora', (tester) async {
      await controller.load();
      controller.onSearchChanged('pix');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      controller.clearSearch();
      await tester.pump();

      expect(controller.isSearching, isFalse);
      expect(controller.filter.isEmpty, isTrue);
      expect(repository.feedCalls, 2);
    });

    testWidgets('mais páginas de resultados com o mesmo texto', (tester) async {
      repository.newsResults
        ..clear()
        ..addAll([
          Right(page(1, ['p1'], hasMore: true)),
          Right(page(2, ['p2'], hasMore: false)),
        ]);
      await controller.load();
      controller.onSearchChanged('pix');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      await controller.loadMore();

      expect(repository.newsCalls.last.page, 2);
      expect(repository.newsCalls.last.filter.normalizedSearch, 'pix');
    });
  });

  group('sem internet', () {
    test('cópia guardada: marca e não pagina', () async {
      repository.feedResults[0] = Right(
        newsFeed(recent: newsItems(20), hasMore: true, isFromCache: true),
      );

      await controller.load();
      await controller.loadMore();

      expect(controller.isFromCache, isTrue);
      expect(controller.hasMore, isFalse);
      expect(controller.isEnd, isFalse);
      expect(repository.feedPageCalls, isEmpty);
    });

    test('atualizar com sucesso tira a marca', () async {
      repository.feedResults
        ..clear()
        ..addAll([Right(newsFeed(isFromCache: true)), Right(newsFeed())]);
      await controller.load();

      await controller.refresh();

      expect(controller.isFromCache, isFalse);
    });

    test('categoria sem internet → erro; "Todas" tenta o feed', () async {
      repository.feedResults[0] = Right(newsFeed(isFromCache: true));
      repository.newsResults[0] = const Left(ConnectionFailure());
      await controller.load();

      await controller.selectCategory('phishing');
      expect(controller.status, FeedStatus.error);
      expect(controller.failure, isA<ConnectionFailure>());

      await controller.selectCategory(null);
      expect(controller.status, FeedStatus.loaded);
      expect(controller.isFromCache, isTrue);
      expect(repository.feedCalls, 2);
    });
  });
}
