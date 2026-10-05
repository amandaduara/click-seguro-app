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
}
