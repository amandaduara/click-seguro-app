import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/auth_field.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/field_error.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/login_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/validators/credentials_validator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late LoginUseCase login;

  setUp(() {
    repository = FakeAuthRepository();
    login = LoginUseCase(repository, const CredentialsValidator());
  });

  test('e-mail inválido é barrado sem chamar o repository', () async {
    final result = await login(email: 'maria@', password: 'x');

    final failure = result.getLeft().toNullable();
    expect(failure, isA<InvalidFormFailure>());
    expect((failure! as InvalidFormFailure).fieldErrors, {
      AuthField.email: FieldError.emailInvalid,
    });
    expect(repository.loginCalls, 0);
  });

  test('senha vazia é barrada', () async {
    final result = await login(email: 'maria@exemplo.com', password: '');

    expect((result.getLeft().toNullable()! as InvalidFormFailure).fieldErrors, {
      AuthField.password: FieldError.required,
    });
  });

  test('válido repassa o e-mail sem espaços e devolve o resultado', () async {
    repository.loginResult = const Left(ServerFailure());

    final result = await login(
      email: ' maria@exemplo.com ',
      password: ' Senha@123',
    );

    expect(repository.lastArgs, {
      'email': 'maria@exemplo.com',
      'password': ' Senha@123',
    });
    expect(result.getLeft().toNullable(), isA<ServerFailure>());
  });
}
