import 'package:click_seguro_app/modules/authentication/domain/enums/password_rule.dart';
import 'dart:async';

import 'package:click_seguro_app/modules/authentication/domain/enums/auth_field.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/field_error.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/authentication_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../fakes/controller_factory.dart';
import '../../fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthenticationController controller;

  setUp(() {
    repository = FakeAuthRepository();
    controller = buildAuthenticationController(repository);
  });

  Future<void> submitLogin({String password = 'Senha@123'}) =>
      controller.submit(email: 'maria@exemplo.com', password: password);

  group('US1', () {
    test('sucesso alterna isSubmitting e marca authenticated', () async {
      final submitting = <bool>[];
      controller.addListener(() => submitting.add(controller.isSubmitting));

      await submitLogin();

      expect(submitting, [true, false]);
      expect(controller.authenticated, isTrue);
      expect(controller.failure, isNull);
    });

    test('formulário inválido vai para fieldErrors', () async {
      await controller.submit(email: 'maria@', password: '');

      expect(controller.fieldErrors, {
        AuthField.email: FieldError.emailInvalid,
        AuthField.password: FieldError.required,
      });
      expect(controller.failure, isNull);
      expect(controller.authenticated, isFalse);
    });

    test('senha errada vai para failure', () async {
      repository.loginResult = const Left(InvalidCredentialsFailure());

      await submitLogin();

      expect(controller.failure, isA<InvalidCredentialsFailure>());
      expect(controller.authenticated, isFalse);
    });

    test('segundo envio durante o primeiro é ignorado', () async {
      repository.gate = Completer<void>();

      final first = submitLogin();
      await submitLogin();
      repository.gate!.complete();
      await first;

      expect(repository.loginCalls, 1);
    });

    test('alterna a visibilidade da senha', () {
      expect(controller.isPasswordVisible, isFalse);

      controller.togglePasswordVisibility();

      expect(controller.isPasswordVisible, isTrue);
    });

    test('reset volta ao estado inicial', () async {
      repository.loginResult = const Left(InvalidCredentialsFailure());
      await submitLogin();
      controller.togglePasswordVisibility();

      controller.reset();

      expect(controller.failure, isNull);
      expect(controller.fieldErrors, isEmpty);
      expect(controller.isPasswordVisible, isFalse);
      expect(controller.authenticated, isFalse);
    });
  });

  group('US2', () {
    Future<void> submitRegister() => controller.submit(
      name: 'Maria Silva',
      email: 'maria@exemplo.com',
      password: 'Senha@123',
    );

    test('trocar de modo limpa erros e falha', () async {
      await controller.submit(email: 'maria@', password: '');
      repository.loginResult = const Left(InvalidCredentialsFailure());

      controller.setMode(AuthMode.register);

      expect(controller.mode, AuthMode.register);
      expect(controller.fieldErrors, isEmpty);
      expect(controller.failure, isNull);
    });

    test('regras da senha acompanham a digitação', () {
      controller.onPasswordChanged('Ab1');

      expect(controller.passwordRules, {
        PasswordRule.uppercase,
        PasswordRule.lowercase,
        PasswordRule.digit,
      });
    });

    test('cadastro com sucesso marca authenticated', () async {
      controller.setMode(AuthMode.register);

      await submitRegister();

      expect(repository.registerCalls, 1);
      expect(repository.loginCalls, 0);
      expect(controller.authenticated, isTrue);
    });

    test('e-mail duplicado fica em failure e no modo cadastro', () async {
      repository.registerResult = const Left(EmailAlreadyExistsFailure());
      controller.setMode(AuthMode.register);

      await submitRegister();

      expect(controller.failure, isA<EmailAlreadyExistsFailure>());
      expect(controller.mode, AuthMode.register);
    });

    test('conta criada sem login volta ao modo entrar com o aviso', () async {
      repository.registerResult = const Left(AccountCreatedFailure());
      controller.setMode(AuthMode.register);

      await submitRegister();

      expect(controller.mode, AuthMode.login);
      expect(controller.failure, isA<AccountCreatedFailure>());
      expect(controller.authenticated, isFalse);
    });
  });
}
