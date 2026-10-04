import 'package:click_seguro_app/modules/authentication/domain/enums/auth_field.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/field_error.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/validate_auth_form_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/validators/credentials_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validate = ValidateAuthFormUseCase(CredentialsValidator());

  test('login: só e-mail válido e senha não vazia', () {
    expect(
      validate(registration: false, email: 'maria@exemplo.com', password: 'x'),
      isEmpty,
    );
  });

  test('cadastro: exige nome, e-mail e as 5 regras da senha', () {
    expect(
      validate(
        registration: true,
        name: 'Maria Silva',
        email: 'maria@exemplo.com',
        password: 'Senha1234',
      ),
      {AuthField.password: FieldError.passwordRules},
    );
    expect(
      validate(
        registration: true,
        name: 'Maria Silva',
        email: 'maria@exemplo.com',
        password: 'Senha@123',
      ),
      isEmpty,
    );
  });
}
