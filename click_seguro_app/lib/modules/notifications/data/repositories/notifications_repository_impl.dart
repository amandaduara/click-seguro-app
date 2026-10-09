import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/api_client/api_failure_mapper.dart';
import 'package:click_seguro_app/modules/notifications/data/datasources/alerts_local_data_source.dart';
import 'package:click_seguro_app/modules/notifications/data/datasources/alerts_remote_data_source.dart';
import 'package:click_seguro_app/modules/notifications/data/models/alerts_snapshot_model.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alerts_snapshot.dart';
import 'package:click_seguro_app/modules/notifications/domain/repositories/notifications_repository.dart';
import 'package:fpdart/fpdart.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._remote, this._local);

  final AlertsRemoteDataSource _remote;
  final AlertsLocalDataSource _local;

  @override
  Future<Either<Failure, AlertsSnapshot>> getSnapshot() =>
      _guardLocal(() async {
        final model = await _local.read();
        return model?.toEntity() ?? const AlertsSnapshot();
      });

  @override
  Future<Either<Failure, Unit>> saveSnapshot(AlertsSnapshot snapshot) =>
      _guardLocal(() async {
        await _local.write(AlertsSnapshotModel.fromEntity(snapshot));
        return unit;
      });

  @override
  Future<Either<Failure, List<AlertEntity>>> fetchNewAlerts({
    required DateTime since,
    required int limit,
  }) => _guardRemote(() async {
    final models = await _remote.fetchNewAlerts(since: since, limit: limit);
    return [for (final model in models) model.toEntity()];
  });

  @override
  Future<Either<Failure, bool>> getReceiveAlerts() =>
      _guardRemote(_remote.getReceiveAlerts);

  @override
  Future<Either<Failure, Unit>> clear() => _guardLocal(() async {
    await _local.clear();
    return unit;
  });

  Future<Either<Failure, T>> _guardRemote<T>(
    Future<T> Function() action,
  ) async {
    try {
      return Right(await action());
    } on ApiException catch (e) {
      return Left(e.toFailure());
    }
  }

  /// Armazenamento que lança (disco cheio, dado corrompido) vira
  /// [CacheFailure].
  Future<Either<Failure, T>> _guardLocal<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } catch (_) {
      return const Left(CacheFailure());
    }
  }
}
