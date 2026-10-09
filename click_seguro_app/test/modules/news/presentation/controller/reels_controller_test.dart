import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/like_result_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reels_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/failures/news_failures.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/reels_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/reels_status.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../fakes/fake_news_repository.dart';
import '../../fakes/reels_controller_factory.dart';

void main() {
  late FakeNewsRepository repository;
  late ValueNotifier<UserSessionStatus> session;
  late ReelsController controller;

  setUp(() {
    repository = FakeNewsRepository();
    session = ValueNotifier(UserSessionStatus.guest);
    controller = buildReelsController(repository, session);
  });

  tearDown(() => controller.dispose());

  /// 1ª parte com [count] Reels `r1…` e, se [next], o cursor `c2`.
  void firstPage(int count, {String? next}) => repository.reelsResults[null] =
      Right(ReelsPageEntity(items: reels(count), nextCursor: next));

  List<String> ids() => controller.reels.map((r) => r.id).toList();

  group('carga e posição', () {
    test('antes do open: initial, sem pedido', () {
      expect(controller.status, ReelsStatus.initial);
      expect(repository.reelsCalls, isEmpty);
    });

    test('open carrega a 1ª parte no índice 0', () async {
      firstPage(3);
      final states = <ReelsStatus>[];
      controller.addListener(() => states.add(controller.status));

      await controller.open();

      expect(states.first, ReelsStatus.loading);
      expect(controller.status, ReelsStatus.loaded);
      expect(ids(), ['r1', 'r2', 'r3']);
      expect(controller.currentIndex, 0);
      expect(repository.reelsCalls, [null]);
    });

    test('open com start na 1ª parte posiciona nele', () async {
      firstPage(3);

      await controller.open('r3');

      expect(controller.currentIndex, 2);
    });

    test('start que não está carregado abre no primeiro', () async {
      firstPage(3);

      await controller.open('xx');

      expect(controller.currentIndex, 0);
    });

    test('já carregado: open com start só posiciona', () async {
      firstPage(3);
      await controller.open();

      await controller.open('r2');
      await controller.open();

      expect(controller.currentIndex, 1);
      expect(repository.reelsCalls, [null]);
    });

    test('falha → error com a Failure; retry recarrega', () async {
      repository.reelsResults[null] = const Left(ConnectionFailure());

      await controller.open();

      expect(controller.status, ReelsStatus.error);
      expect(controller.failure, isA<ConnectionFailure>());

      firstPage(2);
      await controller.retry();

      expect(controller.status, ReelsStatus.loaded);
      expect(controller.failure, isNull);
      expect(ids(), ['r1', 'r2']);
    });

    test('sessão recusada na carga: tenta de novo uma vez', () async {
      repository.reelsQueue.add(const Left(UnauthorizedFailure()));
      firstPage(2);

      await controller.open();

      expect(repository.reelsCalls, [null, null]);
      expect(controller.status, ReelsStatus.loaded);
    });

    test('resposta de carga antiga é ignorada', () async {
      firstPage(2);
      final gate = repository.reelsGate = Completer<void>();
      final first = controller.open();

      firstPage(4);
      repository.reelsGate = null;
      await controller.refresh();
      gate.complete();
      await first;

      expect(ids(), ['r1', 'r2', 'r3', 'r4']);
    });

    test('canGoPrevious, canGoNext e setIndex', () async {
      firstPage(2);
      await controller.open();

      expect(controller.canGoPrevious, isFalse);
      expect(controller.canGoNext, isTrue);

      controller.setIndex(1);

      expect(controller.currentIndex, 1);
      expect(controller.canGoPrevious, isTrue);
      expect(controller.canGoNext, isFalse);
    });
  });

  group('paginação por cursor', () {
    test('faltando 3 ou menos, pede a parte seguinte com o cursor', () async {
      firstPage(10, next: 'c2');
      repository.reelsResults['c2'] = Right(
        ReelsPageEntity(items: reels(2, start: 11), nextCursor: null),
      );
      await controller.open();

      controller.setIndex(5);
      expect(repository.reelsCalls, [null]);

      controller.setIndex(6);
      await pumpEventQueue();

      expect(repository.reelsCalls, [null, 'c2']);
      expect(controller.reels, hasLength(12));
      expect(controller.hasMore, isFalse);
    });

    test('start perto do fim já pede a parte seguinte', () async {
      firstPage(10, next: 'c2');

      await controller.open('r9');
      await pumpEventQueue();

      expect(repository.reelsCalls, [null, 'c2']);
    });

    test('não repete Reels e para quando nada novo chega', () async {
      firstPage(4, next: 'c2');
      repository.reelsResults['c2'] = Right(
        ReelsPageEntity(items: reels(4), nextCursor: 'c3'),
      );
      await controller.open();

      controller.setIndex(1);
      await pumpEventQueue();

      expect(ids(), ['r1', 'r2', 'r3', 'r4']);
      expect(controller.hasMore, isFalse);
      controller.setIndex(3);
      await pumpEventQueue();
      expect(repository.reelsCalls, [null, 'c2']);
    });

    test('sem mais partes, não pede; isEnd', () async {
      firstPage(2);
      await controller.open();

      controller.setIndex(1);
      await pumpEventQueue();

      expect(repository.reelsCalls, [null]);
      expect(controller.isEnd, isTrue);
    });

    test('dois setIndex seguidos fazem um pedido só', () async {
      firstPage(4, next: 'c2');
      await controller.open();
      repository.reelsGate = Completer<void>();

      controller.setIndex(1);
      controller.setIndex(2);
      expect(controller.isLoadingMore, isTrue);
      repository.reelsGate!.complete();
      await pumpEventQueue();

      expect(repository.reelsCalls, [null, 'c2']);
    });

    test(
      'falha na parte seguinte mantém os Reels; loadMore tenta de novo',
      () async {
        firstPage(4, next: 'c2');
        repository.reelsResults['c2'] = const Left(ServerFailure());
        await controller.open();

        controller.setIndex(1);
        await pumpEventQueue();

        expect(controller.loadMoreFailure, isA<ServerFailure>());
        expect(ids(), hasLength(4));
        controller.setIndex(2);
        await pumpEventQueue();
        expect(repository.reelsCalls, [null, 'c2']);

        repository.reelsResults['c2'] = Right(
          ReelsPageEntity(items: reels(1, start: 5), nextCursor: null),
        );
        await controller.loadMore();

        expect(controller.loadMoreFailure, isNull);
        expect(ids(), hasLength(5));
      },
    );
  });

  group('curtir', () {
    setUp(() async {
      repository.reelsResults[null] = Right(
        ReelsPageEntity(items: [reel('r1'), reel('r2')], nextCursor: null),
      );
      await controller.open();
    });

    test('muda na hora e depois fica com o que o servidor devolveu', () async {
      repository.likeGate = Completer<void>();
      repository.likeResults.add(
        const Right(LikeResultEntity(liked: true, likesCount: 10)),
      );

      final pending = controller.toggleLike('r1');

      expect(controller.reels.first.isLiked, isTrue);
      expect(controller.reels.first.likesCount, 4);
      expect(controller.isLikePending('r1'), isTrue);

      repository.likeGate!.complete();
      await pending;

      expect(controller.reels.first.isLiked, isTrue);
      expect(controller.reels.first.likesCount, 10);
      expect(controller.isLikePending('r1'), isFalse);
    });

    test('toque durante o pedido é ignorado', () async {
      repository.likeGate = Completer<void>();

      final first = controller.toggleLike('r1');
      await controller.toggleLike('r1');
      repository.likeGate!.complete();
      await first;

      expect(repository.likeCalls, ['r1']);
    });

    test('descurtir desce 1 na hora', () async {
      await controller.toggleLike('r1');
      repository.likeGate = Completer<void>();
      repository.likeResults.add(
        const Right(LikeResultEntity(liked: false, likesCount: 3)),
      );

      final pending = controller.toggleLike('r1');

      expect(controller.reels.first.isLiked, isFalse);
      expect(controller.reels.first.likesCount, 3);
      repository.likeGate!.complete();
      await pending;
    });

    test('já curtido antes: o servidor desfaz e o app mostra isso', () async {
      repository.likeResults.add(
        const Right(LikeResultEntity(liked: false, likesCount: 2)),
      );

      await controller.toggleLike('r1');

      expect(controller.reels.first.isLiked, isFalse);
      expect(controller.reels.first.likesCount, 2);
    });

    test('falha volta ao estado anterior e avisa', () async {
      final messages = <ReelsMessage>[];
      controller.messages.listen(messages.add);
      repository.likeResults.add(const Left(NewsNotFoundFailure()));

      await controller.toggleLike('r1');
      await pumpEventQueue();

      expect(controller.reels.first.isLiked, isFalse);
      expect(controller.reels.first.likesCount, 3);
      expect(messages.single.type, ReelsMessageType.error);
      expect(messages.single.failureKey, const NewsNotFoundFailure().message);
    });

    test('estado mantido ao passar para outro Reel e voltar', () async {
      await controller.toggleLike('r1');

      controller.setIndex(1);
      controller.setIndex(0);

      expect(controller.reels.first.isLiked, isTrue);
      expect(controller.reels.first.likesCount, 4);
    });
  });

  group('salvar', () {
    late List<ReelsMessage> messages;

    setUp(() async {
      repository.reelsResults[null] = Right(
        ReelsPageEntity(items: [reel('r1')], nextCursor: null),
      );
      await controller.open();
      messages = [];
      controller.messages.listen(messages.add);
    });

    test('salvar: na hora, depois o servidor, e avisa "salva"', () async {
      repository.saveGate = Completer<void>();

      final pending = controller.toggleSave('r1');

      expect(controller.reels.first.isSaved, isTrue);
      expect(controller.isSavePending('r1'), isTrue);
      repository.saveGate!.complete();
      await pending;
      await pumpEventQueue();

      expect(controller.reels.first.isSaved, isTrue);
      expect(messages.single.type, ReelsMessageType.saved);
    });

    test('o estado final é o do servidor; false avisa "removida"', () async {
      repository.saveResults.add(const Right(false));

      await controller.toggleSave('r1');
      await pumpEventQueue();

      expect(controller.reels.first.isSaved, isFalse);
      expect(messages.single.type, ReelsMessageType.removed);
    });

    test('toque durante o pedido é ignorado', () async {
      repository.saveGate = Completer<void>();

      final first = controller.toggleSave('r1');
      await controller.toggleSave('r1');
      repository.saveGate!.complete();
      await first;

      expect(repository.saveCalls, ['r1']);
    });

    test('falha volta ao estado anterior e avisa', () async {
      repository.saveResults.add(const Left(ConnectionFailure()));

      await controller.toggleSave('r1');
      await pumpEventQueue();

      expect(controller.reels.first.isSaved, isFalse);
      expect(messages.single.type, ReelsMessageType.error);
    });
  });

  group('sessão', () {
    test('mudou depois da carga: o próximo open recarrega do início', () async {
      firstPage(3);
      await controller.open();
      controller.setIndex(2);

      session.value = UserSessionStatus.authenticated;
      await controller.open();

      expect(repository.reelsCalls, [null, null]);
      expect(controller.currentIndex, 0);
    });

    test('sem mudança, open não pede de novo', () async {
      firstPage(3);
      await controller.open();

      await controller.open();

      expect(repository.reelsCalls, [null]);
    });

    test('mudança antes da 1ª carga não marca nada', () async {
      session.value = UserSessionStatus.authenticated;
      firstPage(1);

      await controller.open();
      await controller.open();

      expect(repository.reelsCalls, [null]);
    });
  });
}
