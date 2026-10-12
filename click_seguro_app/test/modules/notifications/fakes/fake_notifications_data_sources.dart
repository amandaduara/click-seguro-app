import 'dart:async';

import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/notifications/data/datasources/alerts_local_data_source.dart';
import 'package:click_seguro_app/modules/notifications/data/datasources/alerts_remote_data_source.dart';
import 'package:click_seguro_app/modules/notifications/data/models/alert_model.dart';
import 'package:click_seguro_app/modules/notifications/data/models/alerts_snapshot_model.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';

/// Datasource remoto com respostas e erros configuráveis.
class FakeNotificationsRemoteDataSource implements AlertsRemoteDataSource {
  List<AlertEntity> newAlerts = [];
  ApiException? newAlertsError;
  bool receiveAlerts = true;
  ApiException? receiveAlertsError;

  /// Quando definido, [fetchNewAlerts] só responde depois de concluído.
  Completer<void>? fetchGate;

  final List<({DateTime since, int limit})> fetchCalls = [];
  int receiveCalls = 0;

  @override
  Future<List<AlertModel>> fetchNewAlerts({
    required DateTime since,
    required int limit,
  }) async {
    fetchCalls.add((since: since, limit: limit));
    await fetchGate?.future;
    if (newAlertsError case final error?) throw error;
    return [for (final alert in newAlerts) AlertModel.fromEntity(alert)];
  }

  @override
  Future<bool> getReceiveAlerts() async {
    receiveCalls++;
    if (receiveAlertsError case final error?) throw error;
    return receiveAlerts;
  }
}

/// Registro local em memória.
class FakeNotificationsLocalDataSource implements AlertsLocalDataSource {
  AlertsSnapshotModel? snapshot;
  int writes = 0;
  int clears = 0;

  /// Lançado por [read], [write] e [clear] (armazenamento indisponível).
  Object? saveError;

  @override
  Future<AlertsSnapshotModel?> read() async {
    if (saveError case final error?) throw error;
    return snapshot;
  }

  @override
  Future<void> write(AlertsSnapshotModel snapshot) async {
    if (saveError case final error?) throw error;
    writes++;
    this.snapshot = snapshot;
  }

  @override
  Future<void> clear() async {
    if (saveError case final error?) throw error;
    clears++;
    snapshot = null;
  }
}

ApiException apiError(ApiErrorType type) =>
    ApiException(type: type, message: 'erro de teste');
