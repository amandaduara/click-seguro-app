import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/notifications/data/models/alert_model.dart';
import 'package:click_seguro_app/modules/notifications/data/models/alerts_snapshot_model.dart';
import 'package:click_seguro_app/modules/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/alerts_fixtures.dart';
import '../../fakes/fake_notifications_data_sources.dart';

void main() {
  late FakeNotificationsRemoteDataSource remote;
  late FakeNotificationsLocalDataSource local;
  late NotificationsRepositoryImpl repository;
  final since = DateTime.utc(2026, 10, 9, 15);

  setUp(() {
    remote = FakeNotificationsRemoteDataSource();
    local = FakeNotificationsLocalDataSource();
    repository = NotificationsRepositoryImpl(remote, local);
  });

  group('getSnapshot', () {
    test('com registro: o snapshot', () async {
      local.snapshot = AlertsSnapshotModel.fromEntity(
        snapshot(receiveAlerts: true, alerts: [alert(newsId: 'a')]),
      );

      final result = (await repository.getSnapshot()).toNullable();

      expect(result!.lastCheckAt, snapshot().lastCheckAt);
      expect(result.receiveAlerts, isTrue);
      expect(result.alerts.single.newsId, 'a');
    });

    test('sem registro: snapshot vazio (lastCheckAt nulo)', () async {
      final result = (await repository.getSnapshot()).toNullable();

      expect(result!.lastCheckAt, isNull);
      expect(result.receiveAlerts, isNull);
      expect(result.alerts, isEmpty);
    });

    test('armazenamento que lança: CacheFailure', () async {
      local.saveError = StateError('sem disco');

      final result = await repository.getSnapshot();

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });
  });

  group('saveSnapshot', () {
    test('grava o registro', () async {
      final result = await repository.saveSnapshot(
        snapshot(alerts: [alert(newsId: 'a')]),
      );

      expect(result.isRight(), isTrue);
      expect(local.writes, 1);
      expect(local.snapshot!.alerts.single.newsId, 'a');
    });

    test('falha de armazenamento: CacheFailure', () async {
      local.saveError = StateError('sem disco');

      final result = await repository.saveSnapshot(snapshot());

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });
  });

  group('fetchNewAlerts', () {
    test('sucesso: AlertEntity na ordem do serviço', () async {
      remote.newAlerts = [alert(newsId: 'a'), alert(newsId: 'b')];

      final result = (await repository.fetchNewAlerts(
        since: since,
        limit: 50,
      )).toNullable();

      expect(result!.map((a) => a.newsId), ['a', 'b']);
      expect(remote.fetchCalls.single, (since: since, limit: 50));
    });

    test('conexão e timeout: ConnectionFailure', () async {
      for (final type in [ApiErrorType.connection, ApiErrorType.timeout]) {
        remote.newAlertsError = apiError(type);

        final result = await repository.fetchNewAlerts(since: since, limit: 50);

        expect(
          result.getLeft().toNullable(),
          isA<ConnectionFailure>(),
          reason: type.name,
        );
      }
    });

    test('401: UnauthorizedFailure', () async {
      remote.newAlertsError = apiError(ApiErrorType.unauthorized);

      final result = await repository.fetchNewAlerts(since: since, limit: 50);

      expect(result.getLeft().toNullable(), isA<UnauthorizedFailure>());
    });

    test('servidor e resposta inválida: ServerFailure', () async {
      for (final type in [ApiErrorType.server, ApiErrorType.invalidResponse]) {
        remote.newAlertsError = apiError(type);

        final result = await repository.fetchNewAlerts(since: since, limit: 50);

        expect(
          result.getLeft().toNullable(),
          isA<ServerFailure>(),
          reason: type.name,
        );
      }
    });
  });

  group('getReceiveAlerts', () {
    test('sucesso', () async {
      remote.receiveAlerts = false;

      final result = await repository.getReceiveAlerts();

      expect(result.toNullable(), isFalse);
    });

    test('conexão e timeout: ConnectionFailure', () async {
      for (final type in [ApiErrorType.connection, ApiErrorType.timeout]) {
        remote.receiveAlertsError = apiError(type);

        final result = await repository.getReceiveAlerts();

        expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
      }
    });

    test('401: UnauthorizedFailure', () async {
      remote.receiveAlertsError = apiError(ApiErrorType.unauthorized);

      final result = await repository.getReceiveAlerts();

      expect(result.getLeft().toNullable(), isA<UnauthorizedFailure>());
    });

    test('outros erros: ServerFailure', () async {
      remote.receiveAlertsError = apiError(ApiErrorType.client);

      final result = await repository.getReceiveAlerts();

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
    });
  });

  group('clear', () {
    test('remove o registro', () async {
      local.snapshot = AlertsSnapshotModel(
        alerts: [AlertModel.fromEntity(alert())],
      );

      final result = await repository.clear();

      expect(result.isRight(), isTrue);
      expect(local.clears, 1);
      expect(local.snapshot, isNull);
    });

    test('armazenamento que lança: CacheFailure', () async {
      local.saveError = StateError('sem disco');

      final result = await repository.clear();

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });
  });
}
