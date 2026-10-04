import 'package:click_seguro_app/modules/authentication/domain/enums/auth_field.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/field_error.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/register_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/validators/credentials_validator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late RegisterUseCase register;

  setUp(() {
    repository = FakeAuthRepository();
    register = RegisterUseCase(repository, const CredentialsValidator());
  });

  test('dados inválidos são barrados sem chamar o repository', () async {
    final result = await register(
      name: 'Ana',
      email: 'maria@',
      password: 'fraca',
    );

    expect((result.getLeft().toNullable()! as InvalidFormFailure).fieldErrors, {
      AuthField.name: FieldError.nameLength,
      AuthField.email: FieldError.emailInvalid,
      AuthField.password: FieldError.passwordRules,
    });
    expect(repository.registerCalls, 0);
  });

  test('válido repassa nome e e-mail sem espaços nas pontas', () async {
    final result = await register(
      name: '  Maria Silva ',
      email: ' maria@exemplo.com ',
      password: 'Senha@123',
    );

    expect(result.isRight(), isTrue);
    expect(repository.lastArgs, {
      'name': 'Maria Silva',
      'email': 'maria@exemplo.com',
      'password': 'Senha@123',
    });
  });
}
