import 'package:click_seguro_app/modules/authentication/domain/enums/password_rule.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/evaluate_password_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/validators/credentials_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const evaluate = EvaluatePasswordUseCase(CredentialsValidator());

  test('senha forte atende as 5 regras', () {
    expect(evaluate('Senha@123'), PasswordRule.values.toSet());
  });

  test('senha parcial atende só algumas', () {
    expect(evaluate('Ab1'), {
      PasswordRule.uppercase,
      PasswordRule.lowercase,
      PasswordRule.digit,
    });
  });
}
