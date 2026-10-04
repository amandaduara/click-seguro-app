import 'package:click_seguro_app/modules/authentication/domain/enums/auth_field.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/field_error.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/request_password_reset_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/reset_password_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/verify_reset_code_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/validators/credentials_validator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_auth_repository.dart';

void main() {
  const validator = CredentialsValidator();
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  Map<AuthField, FieldError> errorsOf(Object? failure) =>
      (failure! as InvalidFormFailure).fieldErrors;

  test('pedir código barra e-mail inválido', () async {
    final request = RequestPasswordResetUseCase(repository, validator);

    final invalid = await request('maria@');
    final valid = await request(' maria@exemplo.com ');

    expect(errorsOf(invalid.getLeft().toNullable()), {
      AuthField.email: FieldError.emailInvalid,
    });
    expect(valid.isRight(), isTrue);
    expect(repository.requestResetCalls, 1);
    expect(repository.lastArgs, {'email': 'maria@exemplo.com'});
  });

  test('verificar barra código curto', () async {
    final verify = VerifyResetCodeUseCase(repository, validator);

    final invalid = await verify(email: 'maria@exemplo.com', code: '12345');
    final valid = await verify(email: 'maria@exemplo.com', code: ' 123456 ');

    expect(errorsOf(invalid.getLeft().toNullable()), {
      AuthField.code: FieldError.codeLength,
    });
    expect(valid.isRight(), isTrue);
    expect(repository.lastArgs['code'], '123456');
  });

  test('redefinir barra senha fraca e confirmação diferente', () async {
    final reset = ResetPasswordUseCase(repository, validator);

    final weak = await reset(
      email: 'maria@exemplo.com',
      code: '123456',
      password: 'fraca',
      confirmation: 'fraca',
    );
    final mismatch = await reset(
      email: 'maria@exemplo.com',
      code: '123456',
      password: 'Nova@1234',
      confirmation: 'Nova@12345',
    );
    final ok = await reset(
      email: 'maria@exemplo.com',
      code: '123456',
      password: 'Nova@1234',
      confirmation: 'Nova@1234',
    );

    expect(errorsOf(weak.getLeft().toNullable()), {
      AuthField.password: FieldError.passwordRules,
    });
    expect(errorsOf(mismatch.getLeft().toNullable()), {
      AuthField.passwordConfirmation: FieldError.passwordMismatch,
    });
    expect(ok.isRight(), isTrue);
    expect(repository.resetCalls, 1);
  });
}
