import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alerts_snapshot.dart';
import 'package:click_seguro_app/modules/notifications/domain/repositories/notifications_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetAlertsUseCase {
  GetAlertsUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, AlertsSnapshot>> call() => _repository.getSnapshot();
}
