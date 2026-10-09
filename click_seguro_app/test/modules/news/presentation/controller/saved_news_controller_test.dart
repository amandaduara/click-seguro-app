import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/saved_news_result.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/feed_status.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/saved_news_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../fakes/fake_news_repository.dart';
import '../../fakes/saved_news_controller_factory.dart';

void main() {
  late FakeNewsRepository repository;
  late SavedNewsController controller;

  setUp(() {
    repository = FakeNewsRepository();
    controller = buildSavedNewsController(repository);
  });

  tearDown(() => controller.dispose());

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

  List<String> ids() => controller.items.map((item) => item.id).toList();

  group('carga', () {
    test('antes do load: loading, sem pedido', () {
      expect(controller.status, FeedStatus.loading);
      expect(controller.items, isEmpty);
      expect(repository.savedCalls, isEmpty);
    });

    test('loading → loaded com a página 1', () async {
      repository.savedResults.add(pageOf(20, hasMore: true));
      final states = <FeedStatus>[];
      controller.addListener(() => states.add(controller.status));

      await controller.load();

      expect(states.first, FeedStatus.loading);
      expect(controller.status, FeedStatus.loaded);
      expect(controller.items, hasLength(20));
      expect(controller.page, 1);
      expect(controller.hasMore, isTrue);
      expect(controller.isFromCache, isFalse);
      expect(repository.savedCalls, [1]);
    });

    test('lista vazia: loaded com items vazio', () async {
      repository.savedResults.add(pageOf(0));

      await controller.load();

      expect(controller.status, FeedStatus.loaded);
      expect(controller.items, isEmpty);
      expect(controller.hasMore, isFalse);
    });

    test('cópia do aparelho: isFromCache e sem paginar', () async {
      repository.savedResults.add(pageOf(3, hasMore: true, isFromCache: true));

      await controller.load();

      expect(controller.isFromCache, isTrue);
      expect(controller.hasMore, isFalse);
      await controller.loadMore();
      expect(repository.savedCalls, [1]);
    });

    test(
      'falha sem cópia vira error com a falha; load de novo recupera',
      () async {
        repository.savedResults
          ..add(const Left(ConnectionFailure()))
          ..add(pageOf(2));

        await controller.load();

        expect(controller.status, FeedStatus.error);
        expect(controller.failure, isA<ConnectionFailure>());

        await controller.load();

        expect(controller.status, FeedStatus.loaded);
        expect(controller.failure, isNull);
        expect(controller.items, hasLength(2));
      },
    );

    test('resposta antiga é ignorada', () async {
      final gate = repository.savedGate = Completer<void>();
      repository.savedResults
        ..add(pageOf(1))
        ..add(pageOf(3));

      final first = controller.load();
      final second = controller.load();
      gate.complete();
      await Future.wait([first, second]);

      expect(controller.items, hasLength(3));
    });

    test('dispose durante a carga não dispara erro', () async {
      final gate = repository.savedGate = Completer<void>();
      final other = buildSavedNewsController(repository);

      final loading = other.load();
      other.dispose();
      gate.complete();

      await expectLater(loading, completes);
    });
  });

  group('loadMore', () {
    test('junta a próxima página sem repetir', () async {
      repository.savedResults
        ..add(pageOf(3, hasMore: true))
        ..add(pageOf(3, start: 3, page: 2, hasMore: true));
      await controller.load();

      await controller.loadMore();

      expect(ids(), ['n1', 'n2', 'n3', 'n4', 'n5']);
      expect(controller.page, 2);
      expect(controller.hasMore, isTrue);
      expect(controller.isLoadingMore, isFalse);
      expect(repository.savedCalls, [1, 2]);
    });

    test('página sem nada novo encerra', () async {
      repository.savedResults
        ..add(pageOf(2, hasMore: true))
        ..add(pageOf(2, page: 2, hasMore: true));
      await controller.load();

      await controller.loadMore();

      expect(controller.items, hasLength(2));
      expect(controller.hasMore, isFalse);
    });

    test('sem hasMore não pede', () async {
      repository.savedResults.add(pageOf(2));
      await controller.load();

      await controller.loadMore();

      expect(repository.savedCalls, [1]);
    });

    test('dois loadMore seguidos fazem um pedido só', () async {
      repository.savedResults
        ..add(pageOf(2, hasMore: true))
        ..add(pageOf(1, start: 3, page: 2));
      await controller.load();
      repository.savedGate = Completer<void>();

      final first = controller.loadMore();
      expect(controller.isLoadingMore, isTrue);
      final second = controller.loadMore();
      repository.savedGate!.complete();
      await Future.wait([first, second]);

      expect(repository.savedCalls, [1, 2]);
    });

    test('falha: loadMoreFailure e itens mantidos', () async {
      repository.savedResults
        ..add(pageOf(2, hasMore: true))
        ..add(const Left(ConnectionFailure()));
      await controller.load();

      await controller.loadMore();

      expect(controller.loadMoreFailure, isA<ConnectionFailure>());
      expect(controller.items, hasLength(2));
      expect(controller.status, FeedStatus.loaded);
      expect(controller.hasMore, isTrue);
      expect(controller.isLoadingMore, isFalse);
    });

    test('resposta que chega depois de um refresh é ignorada', () async {
      repository.savedResults
        ..add(pageOf(2, hasMore: true))
        ..add(pageOf(2, start: 3, page: 2))
        ..add(pageOf(1));
      await controller.load();
      final gate = repository.savedGate = Completer<void>();

      final more = controller.loadMore();
      final refreshing = controller.refresh();
      gate.complete();
      await Future.wait([more, refreshing]);

      expect(ids(), ['n1']);
    });
  });

  group('refresh', () {
    test(
      'volta à página 1 e substitui a lista, sem passar por loading',
      () async {
        repository.savedResults
          ..add(pageOf(3, hasMore: true))
          ..add(pageOf(3, start: 3, page: 2))
          ..add(pageOf(2, start: 1));
        await controller.load();
        await controller.loadMore();
        final states = <FeedStatus>[];
        controller.addListener(() => states.add(controller.status));

        await controller.refresh();

        expect(ids(), ['n1', 'n2']);
        expect(controller.page, 1);
        expect(controller.hasMore, isFalse);
        expect(states, everyElement(FeedStatus.loaded));
        expect(repository.savedCalls, [1, 2, 1]);
      },
    );

    test('falha no refresh mantém a lista que já estava na tela', () async {
      repository.savedResults
        ..add(pageOf(2))
        ..add(const Left(ConnectionFailure()));
      await controller.load();

      await controller.refresh();

      expect(controller.status, FeedStatus.loaded);
      expect(ids(), ['n1', 'n2']);
    });

    test('antes de carregar, refresh faz a carga normal', () async {
      repository.savedResults.add(pageOf(2));

      await controller.refresh();

      expect(controller.status, FeedStatus.loaded);
      expect(controller.items, hasLength(2));
    });
  });
}
