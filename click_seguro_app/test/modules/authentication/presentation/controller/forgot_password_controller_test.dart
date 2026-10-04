import 'dart:async';

import 'package:click_seguro_app/modules/authentication/domain/enums/reset_step.dart';
import 'package:click_seguro_app/modules/authentication/domain/failures/auth_failures.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/forgot_password_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/forgot_password_controller_factory.dart';

void main() {
  late FakeAuthRepository repository;
  late DateTime clock;
  late ForgotPasswordController controller;

  setUp(() {
    repository = FakeAuthRepository();
    clock = DateTime(2026, 10, 3, 12);
    controller = buildForgotPasswordController(repository, now: () => clock);
    controller.start('maria@exemplo.com');
  });

  Future<void> toCodeStep() => controller.submitEmail('maria@exemplo.com');

  test('start abre no passo do e-mail com o e-mail informado', () {
    expect(controller.step, ResetStep.email);
    expect(controller.email, 'maria@exemplo.com');
  });

  test('enviar o e-mail vai ao código e inicia a contagem', () async {
    await toCodeStep();

    expect(controller.step, ResetStep.code);
    expect(controller.secondsUntilResend, 60);
    clock = clock.add(const Duration(seconds: 59));
    expect(controller.secondsUntilResend, 1);
    clock = clock.add(const Duration(seconds: 1));
    expect(controller.secondsUntilResend, 0);
  });

  test('reenviar só depois da contagem', () async {
    await toCodeStep();

    await controller.resendCode();
    expect(repository.requestResetCalls, 1);

    clock = clock.add(const Duration(seconds: 60));
    await controller.resendCode();
    expect(repository.requestResetCalls, 2);
    expect(controller.secondsUntilResend, 60);
  });

  test('código inválido fica no passo do código com a falha', () async {
    await toCodeStep();
    repository.verifyCodeResult = const Left(InvalidRecoveryCodeFailure());

    await controller.submitCode('000000');

    expect(controller.step, ResetStep.code);
    expect(controller.failure, isA<InvalidRecoveryCodeFailure>());
  });

  test('fluxo completo termina com completed', () async {
    await toCodeStep();
    await controller.submitCode('123456');
    expect(controller.step, ResetStep.newPassword);

    await controller.submitNewPassword(
      password: 'Nova@1234',
      confirmation: 'Nova@1234',
    );

    expect(controller.completed, isTrue);
    expect(repository.lastArgs, {
      'email': 'maria@exemplo.com',
      'code': '123456',
      'newPassword': 'Nova@1234',
    });
  });

  test('back volta um passo e devolve false no primeiro', () async {
    await toCodeStep();
    await controller.submitCode('123456');

    expect(controller.back(), isTrue);
    expect(controller.step, ResetStep.code);
    expect(controller.back(), isTrue);
    expect(controller.step, ResetStep.email);
    expect(controller.back(), isFalse);
  });

  test('envio duplicado é ignorado', () async {
    repository.gate = Completer<void>();

    final first = toCodeStep();
    await toCodeStep();
    repository.gate!.complete();
    await first;

    expect(repository.requestResetCalls, 1);
  });
}
