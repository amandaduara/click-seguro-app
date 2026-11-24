import 'package:click_seguro_app/modules/authentication/domain/enums/auth_field.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/field_error.dart';
import 'package:click_seguro_app/modules/authentication/domain/validators/credentials_validator.dart';

/// Valida o formulário enquanto a pessoa digita, para habilitar o botão só
/// com tudo correto (RN-001). Mapa vazio = válido.
class ValidateAuthFormUseCase {
  const ValidateAuthFormUseCase(this._validator);

  final CredentialsValidator _validator;

  Map<AuthField, FieldError> call({
    required bool registration,
    String name = '',
    required String email,
    required String password,
  }) => registration
      ? _validator.validateRegistration(
          name: name,
          email: email,
          password: password,
        )
      : _validator.validateLogin(email: email, password: password);
}
