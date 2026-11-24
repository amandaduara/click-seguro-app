import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/common/validators/password_policy.dart';
import 'package:click_seguro_app/modules/settings/domain/failures/settings_failures.dart';
import 'package:click_seguro_app/modules/settings/domain/repositories/account_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Troca a senha (RF-037). A nova segue o RN-001 antes de qualquer pedido;
/// as senhas vão como digitadas (espaços contam).
class ChangePasswordUseCase {
  ChangePasswordUseCase(this._repository);

  final AccountRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!PasswordPolicy.isValid(newPassword)) {
      return const Left(WeakPasswordFailure());
    }
    return _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
