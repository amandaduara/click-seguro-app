import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/notifications/domain/repositories/notifications_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Apaga os alertas da conta ao sair (FR-019).
class ClearAlertsUseCase {
  ClearAlertsUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.clear();
}
