import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/settings/domain/repositories/account_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Liga ou desliga "Alertas de notícias novas" na conta (FR-016).
class SetReceiveAlertsUseCase {
  SetReceiveAlertsUseCase(this._repository);

  final AccountRepository _repository;

  Future<Either<Failure, Unit>> call(bool value) =>
      _repository.setReceiveAlerts(value);
}
