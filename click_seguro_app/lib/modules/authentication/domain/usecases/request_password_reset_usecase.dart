import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/domain/repositories/auth_repository.dart';
import 'package:click_seguro_app/modules/authentication/domain/validators/credentials_validator.dart';
import 'package:fpdart/fpdart.dart';

/// Passo 1 da recuperação: pede o código por e-mail.
class RequestPasswordResetUseCase {
  RequestPasswordResetUseCase(this._repository, this._validator);

  final AuthRepository _repository;
  final CredentialsValidator _validator;

  Future<Either<Failure, Unit>> call(String email) async {
    final errors = _validator.validateEmail(email);
    if (errors.isNotEmpty) return Left(InvalidFormFailure(errors));
    return _repository.requestPasswordReset(email.trim());
  }
}
