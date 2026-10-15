import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/common/validators/password_policy.dart';
import 'package:click_seguro_app/modules/settings/domain/failures/settings_failures.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/change_password_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/logout_usecase.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/change_password_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../fakes/fake_secure_storage_service.dart';
import '../fakes/fake_account_repository.dart';

void main() {
  late FakeAccountRepository repository;
  late UserSessionService session;
  late ChangePasswordController controller;

  setUp(() async {
    repository = FakeAccountRepository();
    session = UserSessionService(FakeSecureStorageService());
    await session.saveSession(
      accessToken: 'acesso-1',
      refreshToken: 'renovacao-1',
      email: 'maria@exemplo.com',
    );
    controller = ChangePasswordController(
      changePassword: ChangePasswordUseCase(repository),
      logout: LogoutUseCase(session),
    );
  });

  tearDown(() => controller.dispose());

  void fill({
    String current = 'Senha@123',
    String newPassword = 'NovaSenha@456',
    String? confirmation,
  }) {
    controller
      ..current.text = current
      ..newPassword.text = newPassword
      ..confirmation.text = confirmation ?? newPassword;
  }

  test('rulesMet acompanha a nova senha', () {
    controller.newPassword.text = 'abc';
    expect(controller.rulesMet, {PasswordRule.lowercase});

    controller.newPassword.text = 'NovaSenha@456';
    expect(controller.rulesMet, PasswordRule.values.toSet());
  });

  test('canSave só com os três preenchidos', () {
    expect(controller.canSave, isFalse);
    controller
      ..current.text = 'a'
      ..newPassword.text = 'b';
    expect(controller.canSave, isFalse);
    controller.confirmation.text = 'c';
    expect(controller.canSave, isTrue);
  });

  test('hasInput com qualquer campo preenchido', () {
    expect(controller.hasInput, isFalse);
    controller.confirmation.text = 'x';
    expect(controller.hasInput, isTrue);
  });

  test('visibilidade de cada campo alterna sozinha', () {
    expect(controller.isVisible(PasswordField.current), isFalse);

    controller.toggleVisibility(PasswordField.current);

    expect(controller.isVisible(PasswordField.current), isTrue);
    expect(controller.isVisible(PasswordField.newPassword), isFalse);
  });

  group('save valida antes de enviar', () {
    test('vazios → required em cada um', () async {
      final result = await controller.save();

      expect(result, ChangePasswordResult.invalid);
      expect(controller.errors, {
        PasswordField.current: PasswordFieldError.required,
        PasswordField.newPassword: PasswordFieldError.required,
        PasswordField.confirmation: PasswordFieldError.required,
      });
      expect(repository.changeCalls, isEmpty);
    });

    test('regras faltando → rulesNotMet', () async {
      fill(newPassword: 'fraca');

      await controller.save();

      expect(
        controller.errors[PasswordField.newPassword],
        PasswordFieldError.rulesNotMet,
      );
      expect(repository.changeCalls, isEmpty);
    });

    test('confirmação diferente → mismatch', () async {
      fill(confirmation: 'OutraSenha@789');

      await controller.save();

      expect(
        controller.errors[PasswordField.confirmation],
        PasswordFieldError.mismatch,
      );
      expect(repository.changeCalls, isEmpty);
    });

    test('editar um campo limpa o erro dele', () async {
      fill(confirmation: 'OutraSenha@789');
      await controller.save();

      controller.confirmation.text = 'NovaSenha@456';

      expect(controller.errors[PasswordField.confirmation], isNull);
    });
  });

  group('respostas do serviço', () {
    test('sucesso → saved', () async {
      fill();

      expect(await controller.save(), ChangePasswordResult.saved);
      expect(repository.changeCalls.single.newPassword, 'NovaSenha@456');
    });

    test('isSaving durante o envio e canSave falso', () async {
      repository.changeGate = Completer<void>();
      fill();

      final saving = controller.save();
      expect(controller.isSaving, isTrue);
      expect(controller.canSave, isFalse);

      repository.changeGate!.complete();
      await saving;
      expect(controller.isSaving, isFalse);
    });

    test('senha atual errada → wrongCurrent e a nova mantida', () async {
      repository.changeResults[0] = const Left(WrongCurrentPasswordFailure());
      fill();

      expect(await controller.save(), ChangePasswordResult.invalid);
      expect(
        controller.errors[PasswordField.current],
        PasswordFieldError.wrongCurrent,
      );
      expect(controller.newPassword.text, 'NovaSenha@456');
      expect(session.isAuthenticated, isTrue);
    });

    test('nova igual à atual → samePassword', () async {
      repository.changeResults[0] = const Left(SamePasswordFailure());
      fill();

      expect(await controller.save(), ChangePasswordResult.invalid);
      expect(
        controller.errors[PasswordField.newPassword],
        PasswordFieldError.samePassword,
      );
    });

    test('falha genérica → failed com saveFailure', () async {
      repository.changeResults[0] = const Left(ServerFailure());
      fill();

      expect(await controller.save(), ChangePasswordResult.failed);
      expect(controller.saveFailure, isA<ServerFailure>());
      expect(session.isAuthenticated, isTrue);
    });

    test('novo login falhou → failed e a sessão é encerrada', () async {
      repository.changeResults[0] = const Left(PasswordChangedReloginFailure());
      fill();

      expect(await controller.save(), ChangePasswordResult.failed);
      expect(controller.saveFailure, isA<PasswordChangedReloginFailure>());
      expect(session.isAuthenticated, isFalse);
    });
  });
}
