import 'package:click_seguro_app/modules/authentication/domain/enums/auth_field.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/field_error.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/password_rule.dart';
import 'package:click_seguro_app/modules/authentication/domain/validators/credentials_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = CredentialsValidator();
  const strong = 'Senha@123';

  group('passwordRules', () {
    test('só minúsculas atende só lowercase', () {
      expect(validator.passwordRules('abc'), {PasswordRule.lowercase});
    });

    test('senha forte atende todas', () {
      expect(validator.passwordRules(strong), PasswordRule.values.toSet());
    });

    test('7 ou 65 caracteres falham length', () {
      expect(
        validator.passwordRules('Ab@1234'),
        isNot(contains(PasswordRule.length)),
      );
      expect(
        validator.passwordRules('Ab@1${'x' * 61}'),
        isNot(contains(PasswordRule.length)),
      );
      expect(
        validator.passwordRules('Ab@1${'x' * 60}'),
        contains(PasswordRule.length),
      );
    });

    test('espaço conta como caractere especial', () {
      expect(validator.passwordRules('a b'), contains(PasswordRule.special));
    });
  });

  group('validateRegistration', () {
    test('tudo válido devolve mapa vazio', () {
      expect(
        validator.validateRegistration(
          name: '  Maria Silva  ',
          email: ' maria@exemplo.com ',
          password: strong,
        ),
        isEmpty,
      );
    });

    test('nome curto ou longo', () {
      expect(
        validator.validateRegistration(
          name: 'Ana',
          email: 'maria@exemplo.com',
          password: strong,
        ),
        {AuthField.name: FieldError.nameLength},
      );
      expect(
        validator.validateRegistration(
          name: 'a' * 151,
          email: 'maria@exemplo.com',
          password: strong,
        ),
        {AuthField.name: FieldError.nameLength},
      );
    });

    for (final email in [
      'maria@',
      '.maria@x.com',
      'ma..ria@x.com',
      'maria@x',
      '${'a' * 250}@x.com',
    ]) {
      test('e-mail inválido: $email', () {
        expect(
          validator.validateRegistration(
            name: 'Maria Silva',
            email: email,
            password: strong,
          ),
          {AuthField.email: FieldError.emailInvalid},
        );
      });
    }

    test('senha fraca', () {
      expect(
        validator.validateRegistration(
          name: 'Maria Silva',
          email: 'maria@exemplo.com',
          password: 'senha123',
        ),
        {AuthField.password: FieldError.passwordRules},
      );
    });

    test('campos vazios são required', () {
      expect(
        validator.validateRegistration(name: ' ', email: '', password: ''),
        {
          AuthField.name: FieldError.required,
          AuthField.email: FieldError.required,
          AuthField.password: FieldError.required,
        },
      );
    });
  });

  group('validateLogin', () {
    test('senha só precisa não estar vazia', () {
      expect(
        validator.validateLogin(email: 'maria@exemplo.com', password: 'x'),
        isEmpty,
      );
    });

    test('senha vazia e e-mail inválido', () {
      expect(validator.validateLogin(email: 'maria@', password: ''), {
        AuthField.email: FieldError.emailInvalid,
        AuthField.password: FieldError.required,
      });
    });
  });

  group('recuperação', () {
    test('validateEmail', () {
      expect(validator.validateEmail('maria@exemplo.com'), isEmpty);
      expect(validator.validateEmail('x'), {
        AuthField.email: FieldError.emailInvalid,
      });
    });

    test('validateCode', () {
      expect(validator.validateCode('12345'), {
        AuthField.code: FieldError.codeLength,
      });
      expect(validator.validateCode('123456'), isEmpty);
      expect(validator.validateCode(''), {AuthField.code: FieldError.required});
    });

    test('validateNewPassword', () {
      expect(
        validator.validateNewPassword(password: strong, confirmation: strong),
        isEmpty,
      );
      expect(
        validator.validateNewPassword(password: strong, confirmation: 'outra'),
        {AuthField.passwordConfirmation: FieldError.passwordMismatch},
      );
      expect(
        validator.validateNewPassword(password: 'fraca', confirmation: 'fraca'),
        {AuthField.password: FieldError.passwordRules},
      );
    });

    test('o mapa devolvido não pode ser alterado', () {
      final errors = validator.validateCode('1');
      expect(
        () => errors[AuthField.email] = FieldError.required,
        throwsUnsupportedError,
      );
    });
  });
}
