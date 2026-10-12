import 'dart:async';

import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alerts_snapshot.dart';
import 'package:click_seguro_app/modules/notifications/domain/repositories/notifications_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Repository em memória: o registro guardado é [stored]; tudo o que o caso
/// de uso e o controller pedem fica nas listas de chamadas.
class FakeNotificationsRepository implements NotificationsRepository {
  AlertsSnapshot stored = const AlertsSnapshot();
  Failure? getSnapshotError;
  Failure? saveError;

  List<AlertEntity> newAlerts = [];
  Failure? newAlertsError;
  bool receiveAlerts = true;
  Failure? receiveAlertsError;

  /// Quando definido, [fetchNewAlerts] só responde depois de concluído.
  Completer<void>? fetchGate;

  int getSnapshotCalls = 0;
  int receiveCalls = 0;
  int clearCalls = 0;
  final List<({DateTime since, int limit})> fetchCalls = [];

  /// Cada registro gravado, na ordem.
  final List<AlertsSnapshot> saves = [];

  @override
  Future<Either<Failure, AlertsSnapshot>> getSnapshot() async {
    getSnapshotCalls++;
    if (getSnapshotError case final error?) return Left(error);
    return Right(stored);
  }

  @override
  Future<Either<Failure, Unit>> saveSnapshot(AlertsSnapshot snapshot) async {
    if (saveError case final error?) return Left(error);
    saves.add(snapshot);
    stored = snapshot;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<AlertEntity>>> fetchNewAlerts({
    required DateTime since,
    required int limit,
  }) async {
    fetchCalls.add((since: since, limit: limit));
    await fetchGate?.future;
    if (newAlertsError case final error?) return Left(error);
    return Right(newAlerts);
  }

  @override
  Future<Either<Failure, bool>> getReceiveAlerts() async {
    receiveCalls++;
    if (receiveAlertsError case final error?) return Left(error);
    return Right(receiveAlerts);
  }

  @override
  Future<Either<Failure, Unit>> clear() async {
    clearCalls++;
    stored = const AlertsSnapshot();
    return const Right(unit);
  }
}
