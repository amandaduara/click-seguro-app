import 'package:click_seguro_app/modules/authentication/domain/validators/credentials_validator.dart';
import 'package:click_seguro_app/modules/common/validators/password_policy.dart';

/// Regras da senha atendidas, para a lista viva do cadastro (FR-005).
class EvaluatePasswordUseCase {
  const EvaluatePasswordUseCase(this._validator);

  final CredentialsValidator _validator;

  Set<PasswordRule> call(String password) => _validator.passwordRules(password);
}
