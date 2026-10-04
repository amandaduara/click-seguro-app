import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/domain/repositories/auth_repository.dart';
import 'package:click_seguro_app/modules/authentication/domain/validators/credentials_validator.dart';
import 'package:fpdart/fpdart.dart';

/// Passo 3: grava a nova senha (RN-001) com o código já conferido.
class ResetPasswordUseCase {
  ResetPasswordUseCase(this._repository, this._validator);

  final AuthRepository _repository;
  final CredentialsValidator _validator;

  Future<Either<Failure, Unit>> call({
    required String email,
    required String code,
    required String password,
    required String confirmation,
  }) async {
    final errors = _validator.validateNewPassword(
      password: password,
      confirmation: confirmation,
    );
    if (errors.isNotEmpty) return Left(InvalidFormFailure(errors));
    return _repository.resetPassword(
      email: email,
      code: code,
      newPassword: password,
    );
  }
}
