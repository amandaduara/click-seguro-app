import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/authentication/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

/// "Continuar sem login" (RF-005): sem conta e sem rede.
class EnterAsGuestUseCase {
  EnterAsGuestUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.enterAsGuest();
}
