import 'package:click_seguro_app/modules/authentication/domain/enums/password_rule.dart';
import 'package:click_seguro_app/modules/authentication/domain/validators/credentials_validator.dart';

/// Regras da senha atendidas, para a lista viva do cadastro (FR-005).
class EvaluatePasswordUseCase {
  const EvaluatePasswordUseCase(this._validator);

  final CredentialsValidator _validator;

  Set<PasswordRule> call(String password) => _validator.passwordRules(password);
}
