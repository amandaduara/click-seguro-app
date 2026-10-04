import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/domain/repositories/auth_repository.dart';
import 'package:click_seguro_app/modules/authentication/domain/validators/credentials_validator.dart';
import 'package:fpdart/fpdart.dart';

/// Passo 2: confere o código antes da troca, porque a redefinição sempre
/// responde "ok" (FR-014).
class VerifyResetCodeUseCase {
  VerifyResetCodeUseCase(this._repository, this._validator);

  final AuthRepository _repository;
  final CredentialsValidator _validator;

  Future<Either<Failure, Unit>> call({
    required String email,
    required String code,
  }) async {
    final errors = _validator.validateCode(code);
    if (errors.isNotEmpty) return Left(InvalidFormFailure(errors));
    return _repository.verifyResetCode(email: email, code: code.trim());
  }
}
