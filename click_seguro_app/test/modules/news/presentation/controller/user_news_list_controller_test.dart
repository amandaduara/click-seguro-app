import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_interaction_change.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_list_kind.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/user_news_list_result.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/feed_status.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/user_news_list_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../fakes/fake_news_repository.dart';
import '../../fakes/user_news_list_controller_factory.dart';

void main() {
  late FakeNewsRepository repository;
  late UserNewsListController controller;

  setUp(() {
    repository = FakeNewsRepository();
    controller = buildUserNewsListController(repository);
  });

  tearDown(() => controller.dispose());

  Right<Failure, UserNewsListResult> pageOf(
    int count, {
    int start = 1,
    int page = 1,
    bool hasMore = false,
    bool isFromCache = false,
  }) => Right(
    UserNewsListResult(
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
      final other = buildUserNewsListController(repository);

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

  group('mudança confirmada em outra tela (desmarcar no detalhe)', () {
    Future<void> emit(NewsInteractionChange change) async {
      repository.interactions.add(change);
      await Future<void>.delayed(Duration.zero);
    }

    test(
      'salvas: desmarcar salvar tira o item sem pedido nem loading',
      () async {
        repository.savedResults.add(pageOf(3));
        await controller.load();
        final states = <FeedStatus>[];
        controller.addListener(() => states.add(controller.status));

        await emit(const NewsInteractionChange(newsId: 'n2', isSaved: false));

        expect(ids(), ['n1', 'n3']);
        expect(states, [FeedStatus.loaded]);
        expect(repository.savedCalls, [1]);
      },
    );

    test(
      'resposta montada antes da confirmação não traz o item de volta',
      () async {
        repository.savedResults
          ..add(pageOf(3))
          ..add(pageOf(3));
        await controller.load();
        await emit(const NewsInteractionChange(newsId: 'n1', isSaved: false));

        await controller.refresh();

        expect(ids(), ['n2', 'n3']);
      },
    );

    test('salvar de novo deixa o item voltar na próxima carga', () async {
      repository.savedResults
        ..add(pageOf(3))
        ..add(pageOf(3));
      await controller.load();
      await emit(const NewsInteractionChange(newsId: 'n1', isSaved: false));
      await emit(const NewsInteractionChange(newsId: 'n1', isSaved: true));

      await controller.refresh();

      expect(ids(), ['n1', 'n2', 'n3']);
    });

    test('salvas ignoram curtidas e leituras', () async {
      repository.savedResults.add(pageOf(2));
      await controller.load();

      await emit(const NewsInteractionChange(newsId: 'n1', isLiked: false));
      await emit(const NewsInteractionChange(newsId: 'n2', isRead: true));

      expect(ids(), ['n1', 'n2']);
    });

    test('curtidas: descurtir tira o item; salvar não mexe', () async {
      final liked = buildUserNewsListController(
        repository,
        kind: NewsListKind.liked,
      );
      addTearDown(liked.dispose);
      repository.savedResults.add(pageOf(3));
      await liked.load();

      await emit(const NewsInteractionChange(newsId: 'n1', isSaved: false));
      await emit(const NewsInteractionChange(newsId: 'n3', isLiked: false));

      expect(liked.items.map((item) => item.id), ['n1', 'n2']);
    });

    test('lidas não mudam com salvar ou curtir', () async {
      final read = buildUserNewsListController(
        repository,
        kind: NewsListKind.read,
      );
      addTearDown(read.dispose);
      repository.savedResults.add(pageOf(2));
      await read.load();

      await emit(const NewsInteractionChange(newsId: 'n1', isSaved: false));
      await emit(const NewsInteractionChange(newsId: 'n2', isLiked: false));

      expect(read.items, hasLength(2));
    });

    test('depois do dispose, para de ouvir as mudanças', () async {
      final other = buildUserNewsListController(repository);
      repository.savedResults.add(pageOf(2));
      await other.load();
      other.dispose();

      await emit(const NewsInteractionChange(newsId: 'n1', isSaved: false));

      expect(other.items, hasLength(2));
    });
  });

  test('com kind read, pede as lidas', () async {
    final readList = buildUserNewsListController(
      repository,
      kind: NewsListKind.read,
    );
    addTearDown(readList.dispose);

    await readList.load();

    expect(repository.listKinds, [NewsListKind.read]);
  });
}
