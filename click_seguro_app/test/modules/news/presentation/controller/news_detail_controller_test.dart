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
}
