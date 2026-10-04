import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/authentication/domain/entities/user_entity.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/domain/repositories/auth_repository.dart';
import 'package:click_seguro_app/modules/authentication/domain/validators/credentials_validator.dart';
import 'package:fpdart/fpdart.dart';

class LoginUseCase {
  LoginUseCase(this._repository, this._validator);

  final AuthRepository _repository;
  final CredentialsValidator _validator;

  /// Valida antes de qualquer rede (SC-004).
  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
  }) async {
    final errors = _validator.validateLogin(email: email, password: password);
    if (errors.isNotEmpty) return Left(InvalidFormFailure(errors));
    return _repository.login(email: email.trim(), password: password);
  }
}
