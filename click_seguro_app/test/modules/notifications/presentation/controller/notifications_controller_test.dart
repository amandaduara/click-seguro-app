import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';
import 'package:click_seguro_app/modules/notifications/presentation/controller/alerts_status.dart';
import 'package:click_seguro_app/modules/notifications/presentation/controller/notifications_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../fakes/alerts_fixtures.dart';
import '../../fakes/fake_notifications_repository.dart';
import '../../fakes/notifications_controller_factory.dart';

void main() {
  late UserSessionService session;
  late FakeNotificationsRepository repository;
  late DateTime now;
  late NotificationsController controller;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    await session.saveSession(
      accessToken: 'tk',
      refreshToken: 'rf',
      email: 'ana@test.com',
    );
    repository = FakeNotificationsRepository();
    now = testNow;
    controller = buildNotificationsController(
      repository,
      session,
      now: () => now,
    );
  });

  tearDown(() => controller.dispose());

  /// Registro já conferido uma hora antes, com [alerts] guardados.
  void stored(List<AlertEntity> alerts) =>
      repository.stored = snapshot(alerts: alerts);

  group('conferência e contador', () {
    test('load: loading → ready com os alertas do registro', () async {
      stored([alert(newsId: 'a'), alert(newsId: 'b', isRead: true)]);
      var notified = 0;
      controller.addListener(() => notified++);

      expect(controller.status, AlertsStatus.loading);
      await controller.load();

      expect(notified, 1);
      expect(controller.status, AlertsStatus.ready);
      expect(controller.alerts.map((a) => a.newsId), ['a', 'b']);
      expect(controller.unreadCount, 1);
    });

    test('1ª conferência da conta: grava o horário e nada mais', () async {
      await controller.load();

      await controller.checkNew();

      expect(repository.saves.single.lastCheckAt, testNow);
      expect(repository.fetchCalls, isEmpty);
      expect(repository.receiveCalls, 0);
      expect(controller.unreadCount, 0);
    });

    test(
      'notícias novas: alertas e contador mudam e avisa os ouvintes',
      () async {
        stored([]);
        repository.newAlerts = [
          alert(
            newsId: 'a',
            publishedAt: testNow.subtract(const Duration(minutes: 10)),
          ),
          alert(
            newsId: 'b',
            publishedAt: testNow.subtract(const Duration(minutes: 20)),
          ),
        ];
        await controller.load();
        var notifications = 0;
        controller.addListener(() => notifications++);

        await controller.checkNew();

        expect(controller.alerts.map((a) => a.newsId), ['a', 'b']);
        expect(controller.unreadCount, 2);
        expect(controller.receiveAlerts, isTrue);
        expect(notifications, greaterThan(0));
        expect(controller.isChecking, isFalse);
      },
    );

    test('falha qualquer: nada muda e nenhuma mensagem é exposta', () async {
      stored([alert(newsId: 'a')]);
      await controller.load();
      final before = repository.stored;

      for (final failure in <Failure>[
        const ServerFailure(),
        const UnauthorizedFailure(),
      ]) {
        repository.newAlertsError = failure;
        await controller.checkNew(force: true);

        expect(controller.alerts.map((a) => a.newsId), ['a']);
        expect(controller.unreadCount, 1);
        expect(controller.lastCheckFailure, isNull);
        expect(repository.saves, isEmpty);
        expect(repository.stored.lastCheckAt, before.lastCheckAt);
      }
    });

    test(
      'só ConnectionFailure preenche lastCheckFailure; sucesso limpa',
      () async {
        stored([alert(newsId: 'a')]);
        await controller.load();

        repository.receiveAlertsError = const ConnectionFailure();
        await controller.checkNew(force: true);
        expect(controller.lastCheckFailure, isA<ConnectionFailure>());
        expect(controller.alerts, hasLength(1));

        repository.receiveAlertsError = null;
        await controller.checkNew(force: true);
        expect(controller.lastCheckFailure, isNull);
      },
    );

    test('automática dentro de 5 minutos é ignorada; force não', () async {
      stored([]);
      await controller.load();

      await controller.checkNew();
      expect(repository.fetchCalls, hasLength(1));

      now = testNow.add(const Duration(minutes: 4));
      await controller.checkNew();
      expect(repository.fetchCalls, hasLength(1));

      await controller.checkNew(force: true);
      expect(repository.fetchCalls, hasLength(2));

      // O intervalo conta da última conferência (a de 4 minutos).
      now = testNow.add(const Duration(minutes: 8));
      await controller.checkNew();
      expect(repository.fetchCalls, hasLength(2));

      now = testNow.add(const Duration(minutes: 9));
      await controller.checkNew();
      expect(repository.fetchCalls, hasLength(3));
    });

    test('falha também conta para o intervalo', () async {
      stored([]);
      repository.newAlertsError = const ConnectionFailure();
      await controller.load();

      await controller.checkNew();
      now = testNow.add(const Duration(minutes: 1));
      await controller.checkNew();

      expect(repository.fetchCalls, hasLength(1));
    });

    test('segunda chamada durante a conferência não pede de novo', () async {
      stored([]);
      repository.fetchGate = Completer<void>();
      await controller.load();

      final first = controller.checkNew();
      await Future<void>.delayed(Duration.zero);
      expect(controller.isChecking, isTrue);
      await controller.checkNew(force: true);
      expect(repository.fetchCalls, hasLength(1));

      repository.fetchGate!.complete();
      await first;
      expect(controller.isChecking, isFalse);
      expect(repository.fetchCalls, hasLength(1));
    });

    test('marcar como lido durante o pedido é preservado (R5)', () async {
      stored([alert(newsId: 'a'), alert(newsId: 'b')]);
      repository.fetchGate = Completer<void>();
      repository.newAlerts = [
        alert(
          newsId: 'c',
          publishedAt: testNow.subtract(const Duration(minutes: 5)),
        ),
      ];
      await controller.load();

      final checking = controller.checkNew();
      await Future<void>.delayed(Duration.zero);
      final marking = controller.markAsRead('a');
      expect(controller.unreadCount, 1);

      repository.fetchGate!.complete();
      await checking;
      await marking;

      expect(controller.unreadCount, 2);
      expect(controller.alerts.where((a) => a.isRead).map((a) => a.newsId), [
        'a',
      ]);
      expect(
        repository.stored.alerts.where((a) => a.isRead).map((a) => a.newsId),
        ['a'],
      );
      expect(repository.stored.alerts.map((a) => a.newsId), contains('c'));
    });

    test('visitante: nenhuma chamada ao repository e contador 0', () async {
      await session.startGuestSession();

      await controller.load();
      await controller.checkNew(force: true);
      await controller.markAsRead('a');

      expect(controller.status, AlertsStatus.ready);
      expect(controller.unreadCount, 0);
      expect(repository.getSnapshotCalls, 0);
      expect(repository.receiveCalls, 0);
      expect(repository.fetchCalls, isEmpty);
      expect(repository.saves, isEmpty);
    });

    test('desconectado: nenhuma chamada ao repository', () async {
      await session.logout();

      await controller.load();
      await controller.checkNew(force: true);

      expect(controller.unreadCount, 0);
      expect(repository.getSnapshotCalls, 0);
      expect(repository.fetchCalls, isEmpty);
    });

    test('sair da conta zera o estado e apaga o registro', () async {
      stored([alert(newsId: 'a')]);
      await controller.load();
      expect(controller.unreadCount, 1);

      await session.logout();
      await Future<void>.delayed(Duration.zero);

      expect(controller.unreadCount, 0);
      expect(controller.alerts, isEmpty);
      expect(repository.clearCalls, 1);
      expect(repository.stored.alerts, isEmpty);
    });

    test('visitante: zera o estado sem apagar o registro', () async {
      stored([alert(newsId: 'a')]);
      await controller.load();

      await session.startGuestSession();
      await Future<void>.delayed(Duration.zero);

      expect(controller.unreadCount, 0);
      expect(repository.clearCalls, 0);
    });

    test('entrar na conta carrega o registro', () async {
      await session.logout();
      await controller.load();
      stored([alert(newsId: 'a')]);

      await session.saveSession(
        accessToken: 'tk',
        refreshToken: 'rf',
        email: 'ana@test.com',
      );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.unreadCount, 1);
    });

    test('resposta que chega depois de sair é descartada', () async {
      stored([]);
      repository.fetchGate = Completer<void>();
      repository.newAlerts = [
        alert(publishedAt: testNow.subtract(const Duration(minutes: 5))),
      ];
      await controller.load();

      final checking = controller.checkNew();
      await Future<void>.delayed(Duration.zero);
      await session.logout();
      repository.fetchGate!.complete();
      await checking;

      expect(controller.unreadCount, 0);
      expect(controller.alerts, isEmpty);
    });
  });

  group('marcar como lido', () {
    test('muda o estado na hora, antes de a gravação terminar', () async {
      stored([alert(newsId: 'a'), alert(newsId: 'b')]);
      await controller.load();
      repository.saves.clear();

      final marking = controller.markAsRead('a');

      expect(controller.unreadCount, 1);
      expect(controller.alerts.first.isRead, isTrue);
      expect(repository.saves, isEmpty);

      await marking;
      expect(repository.saves, hasLength(1));
      expect(repository.stored.alerts.first.isRead, isTrue);
    });

    test('id inexistente: sem efeito e sem erro', () async {
      stored([alert(newsId: 'a')]);
      await controller.load();
      repository.saves.clear();

      await controller.markAsRead('x');

      expect(controller.unreadCount, 1);
      expect(repository.saves, isEmpty);
    });

    test('falha ao gravar mantém o estado em memória', () async {
      stored([alert(newsId: 'a')]);
      await controller.load();
      repository.saveError = const CacheFailure();

      await controller.markAsRead('a');

      expect(controller.unreadCount, 0);
      expect(controller.alerts.single.isRead, isTrue);
    });

    test('persiste: outro controller sobre o mesmo registro vê lido', () async {
      stored([alert(newsId: 'a')]);
      await controller.load();
      await controller.markAsRead('a');

      final other = buildNotificationsController(repository, session);
      addTearDown(other.dispose);
      await other.load();

      expect(other.unreadCount, 0);
      expect(other.alerts.single.isRead, isTrue);
    });
  });
}
