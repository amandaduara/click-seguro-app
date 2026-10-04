import 'package:click_seguro_app/modules/authentication/domain/usecases/evaluate_password_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/request_password_reset_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/reset_password_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/verify_reset_code_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/validators/credentials_validator.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/forgot_password_controller.dart';

import 'fake_auth_repository.dart';

ForgotPasswordController buildForgotPasswordController(
  FakeAuthRepository repository, {
  DateTime Function()? now,
}) {
  const validator = CredentialsValidator();
  return ForgotPasswordController(
    requestReset: RequestPasswordResetUseCase(repository, validator),
    verifyCode: VerifyResetCodeUseCase(repository, validator),
    resetPassword: ResetPasswordUseCase(repository, validator),
    evaluatePassword: const EvaluatePasswordUseCase(validator),
    now: now,
  );
}
