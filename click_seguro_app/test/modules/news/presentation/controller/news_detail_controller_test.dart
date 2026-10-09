import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_detail_entity.dart';
import 'package:click_seguro_app/modules/news/domain/failures/news_failures.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/news_detail_controller.dart';
import 'package:click_seguro_app/modules/news/presentation/controller/news_detail_status.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../fakes/fake_news_repository.dart';
import '../../fakes/news_detail_controller_factory.dart';

void main() {
  late FakeNewsRepository repository;
  late ValueNotifier<UserSessionStatus> session;
  late NewsDetailController controller;

  setUp(() {
    repository = FakeNewsRepository();
    session = ValueNotifier(UserSessionStatus.guest);
    controller = buildNewsDetailController(repository, session);
  });

  tearDown(() => controller.dispose());

  Right<Failure, NewsDetailResult> fromServer(String id) =>
      Right(NewsDetailResult(detail: newsDetail(id), isFromCache: false));

  Right<Failure, NewsDetailResult> fromCache(String id) =>
      Right(NewsDetailResult(detail: newsDetail(id), isFromCache: true));

  group('carga', () {
    test('antes do load: loading, sem pedido', () {
      expect(controller.status, NewsDetailStatus.loading);
      expect(controller.detail, isNull);
      expect(repository.detailCalls, isEmpty);
    });

    test('loading → loaded com o detalhe do servidor', () async {
      final states = <NewsDetailStatus>[];
      controller.addListener(() => states.add(controller.status));

      await controller.load();

      expect(states.first, NewsDetailStatus.loading);
      expect(controller.status, NewsDetailStatus.loaded);
      expect(controller.detail?.id, 'n1');
      expect(controller.isFromCache, isFalse);
      expect(controller.failure, isNull);
      expect(repository.detailCalls, ['n1']);
    });

    test('detalhe vindo da cópia marca isFromCache', () async {
      repository.detailResults.add(fromCache('n1'));

      await controller.load();

      expect(controller.status, NewsDetailStatus.loaded);
      expect(controller.isFromCache, isTrue);
    });

    test('404 vira notFound', () async {
      repository.detailResults.add(const Left(NewsNotFoundFailure()));

      await controller.load();

      expect(controller.status, NewsDetailStatus.notFound);
      expect(controller.detail, isNull);
    });

    test('outra falha vira error com a falha', () async {
      repository.detailResults.add(const Left(ConnectionFailure()));

      await controller.load();

      expect(controller.status, NewsDetailStatus.error);
      expect(controller.failure, isA<ConnectionFailure>());
    });

    test('retry recarrega e limpa o erro', () async {
      repository.detailResults
        ..add(const Left(ConnectionFailure()))
        ..add(fromServer('n1'));
      await controller.load();

      await controller.retry();

      expect(controller.status, NewsDetailStatus.loaded);
      expect(controller.failure, isNull);
      expect(repository.detailCalls, ['n1', 'n1']);
    });

    test('resposta de carga antiga é ignorada', () async {
      final gate = repository.detailGate = Completer<void>();
      repository.detailResults
        ..add(
          Right(
            NewsDetailResult(
              detail: newsDetail('n1', content: 'antigo'),
              isFromCache: false,
            ),
          ),
        )
        ..add(
          Right(
            NewsDetailResult(
              detail: newsDetail('n1', content: 'novo'),
              isFromCache: false,
            ),
          ),
        );

      final first = controller.load();
      final second = controller.load();
      gate.complete();
      await Future.wait([first, second]);

      expect(controller.detail?.content, 'novo');
    });

    test('dispose durante a carga não dispara erro', () async {
      final gate = repository.detailGate = Completer<void>();
      final other = buildNewsDetailController(repository, session);

      final loading = other.load();
      other.dispose();
      gate.complete();

      await expectLater(loading, completes);
    });
  });

  group('registro de leitura', () {
    // Sessão já com conta quando o controller nasce (sem recarga).
    setUp(() {
      controller.dispose();
      session.value = UserSessionStatus.authenticated;
      controller = buildNewsDetailController(repository, session);
    });

    test('com conta e detalhe do servidor chama markAsRead uma vez', () async {
      await controller.load();
      await controller.retry();

      expect(repository.readCalls, ['n1']);
    });

    test('não espera o markAsRead: a tela já está loaded (SC-002)', () async {
      repository.readGate = Completer<void>();

      await controller.load();

      expect(controller.status, NewsDetailStatus.loaded);
      expect(repository.readCalls, ['n1']);
      repository.readGate!.complete();
    });

    test('falha do markAsRead não muda o estado', () async {
      repository.readResults.add(const Left(ConnectionFailure()));

      await controller.load();
      await Future<void>.delayed(Duration.zero);

      expect(controller.status, NewsDetailStatus.loaded);
      expect(controller.failure, isNull);
    });

    test('visitante não chama markAsRead', () async {
      session.value = UserSessionStatus.guest;

      await controller.load();

      expect(repository.readCalls, isEmpty);
    });

    test('detalhe vindo da cópia não chama markAsRead', () async {
      repository.detailResults.add(fromCache('n1'));

      await controller.load();

      expect(repository.readCalls, isEmpty);
    });

    test('erro na carga não chama markAsRead', () async {
      repository.detailResults.add(const Left(ConnectionFailure()));

      await controller.load();

      expect(repository.readCalls, isEmpty);
    });
  });

  group('sessão', () {
    test(
      'virar authenticated com a tela aberta recarrega e registra',
      () async {
        await controller.load();
        expect(repository.detailCalls, ['n1']);
        expect(repository.readCalls, isEmpty);

        session.value = UserSessionStatus.authenticated;
        await Future<void>.delayed(Duration.zero);

        expect(repository.detailCalls, ['n1', 'n1']);
        expect(repository.readCalls, ['n1']);
      },
    );

    test('outras mudanças de sessão não recarregam', () async {
      await controller.load();

      session.value = UserSessionStatus.unauthenticated;
      await Future<void>.delayed(Duration.zero);

      expect(repository.detailCalls, ['n1']);
    });

    test('depois do dispose o listener foi removido', () async {
      final own = ValueNotifier(UserSessionStatus.guest);
      final other = buildNewsDetailController(repository, own);
      await other.load();
      other.dispose();

      own.value = UserSessionStatus.authenticated;
      await Future<void>.delayed(Duration.zero);

      expect(repository.detailCalls, ['n1']);
    });
  });

  group('auto-leitura', () {
    test('autoReadDone começa false', () {
      expect(controller.autoReadDone, isFalse);
    });

    test('markAutoReadDone liga e não desliga', () {
      controller.markAutoReadDone();
      controller.markAutoReadDone();

      expect(controller.autoReadDone, isTrue);
    });

    test(
      'novo load por retry ou por login não reabre a auto-leitura',
      () async {
        await controller.load();
        controller.markAutoReadDone();

        await controller.retry();
        session.value = UserSessionStatus.authenticated;
        await Future<void>.delayed(Duration.zero);

        expect(controller.autoReadDone, isTrue);
      },
    );
  });

  group('salvar', () {
    late List<NewsDetailMessage> messages;

    Future<void> loadWith({bool isSaved = false}) async {
      repository.detailResults.add(
        Right(
          NewsDetailResult(
            detail: newsDetail('n1', isSaved: isSaved),
            isFromCache: false,
          ),
        ),
      );
      await controller.load();
      messages = [];
      controller.messages.listen(messages.add);
    }

    test('na hora inverte e marca isSaving; depois mostra o do servidor e '
        'avisa "salva"', () async {
      await loadWith();
      repository.saveGate = Completer<void>();

      final pending = controller.toggleSave();

      expect(controller.detail?.isSaved, isTrue);
      expect(controller.isSaving, isTrue);
      repository.saveGate!.complete();
      await pending;
      await pumpEventQueue();

      expect(controller.detail?.isSaved, isTrue);
      expect(controller.isSaving, isFalse);
      expect(messages.single.type, NewsDetailMessageType.saved);
      expect(repository.saveCalls, ['n1']);
    });

    test('remover: o servidor devolve false e avisa "removida"', () async {
      await loadWith(isSaved: true);
      repository.saveResults.add(const Right(false));

      await controller.toggleSave();
      await pumpEventQueue();

      expect(controller.detail?.isSaved, isFalse);
      expect(messages.single.type, NewsDetailMessageType.removed);
    });

    test('o estado final é exatamente o devolvido pelo servidor', () async {
      await loadWith();
      repository.saveResults.add(const Right(false));

      await controller.toggleSave();
      await pumpEventQueue();

      expect(controller.detail?.isSaved, isFalse);
      expect(messages.single.type, NewsDetailMessageType.removed);
    });

    test('segundo toque durante o pedido é ignorado', () async {
      await loadWith();
      repository.saveGate = Completer<void>();

      final first = controller.toggleSave();
      await controller.toggleSave();
      repository.saveGate!.complete();
      await first;

      expect(repository.saveCalls, ['n1']);
    });

    test('falha volta ao estado anterior e avisa com a falha', () async {
      await loadWith();
      repository.saveResults.add(const Left(ConnectionFailure()));

      await controller.toggleSave();
      await pumpEventQueue();

      expect(controller.detail?.isSaved, isFalse);
      expect(controller.isSaving, isFalse);
      expect(messages.single.type, NewsDetailMessageType.saveFailed);
      expect(messages.single.failureKey, const ConnectionFailure().message);
    });

    test('404 volta o marcador e vira notFound', () async {
      await loadWith(isSaved: true);
      repository.saveResults.add(const Left(NewsNotFoundFailure()));

      await controller.toggleSave();
      await pumpEventQueue();

      expect(controller.status, NewsDetailStatus.notFound);
      expect(controller.detail?.isSaved, isTrue);
      expect(controller.isSaving, isFalse);
      expect(messages.single.type, NewsDetailMessageType.notFound);
    });

    test('depois de uma falha dá para tentar de novo', () async {
      await loadWith();
      repository.saveResults
        ..add(const Left(ConnectionFailure()))
        ..add(const Right(true));

      await controller.toggleSave();
      await controller.toggleSave();

      expect(controller.detail?.isSaved, isTrue);
      expect(repository.saveCalls, ['n1', 'n1']);
    });

    test('sem detalhe carregado o toque é ignorado', () async {
      await controller.toggleSave();
      expect(repository.saveCalls, isEmpty);

      repository.detailResults.add(const Left(ConnectionFailure()));
      await controller.load();
      await controller.toggleSave();

      expect(controller.status, NewsDetailStatus.error);
      expect(repository.saveCalls, isEmpty);
    });

    test('dispose durante o pedido não dispara erro', () async {
      final other = buildNewsDetailController(repository, session);
      await other.load();
      repository.saveGate = Completer<void>();

      final pending = other.toggleSave();
      other.dispose();
      repository.saveGate!.complete();

      await expectLater(pending, completes);
    });
  });
}
