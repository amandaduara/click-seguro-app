import 'package:click_seguro_app/modules/authentication/domain/usecases/enter_as_guest_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/evaluate_password_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/login_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/register_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/usecases/validate_auth_form_usecase.dart';
import 'package:click_seguro_app/modules/authentication/domain/validators/credentials_validator.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/authentication_controller.dart';

import 'fake_auth_repository.dart';

/// Controller com os usecases reais sobre o [FakeAuthRepository].
AuthenticationController buildAuthenticationController(
  FakeAuthRepository repository,
) {
  const validator = CredentialsValidator();
  return AuthenticationController(
    login: LoginUseCase(repository, validator),
    register: RegisterUseCase(repository, validator),
    evaluatePassword: const EvaluatePasswordUseCase(validator),
    validateForm: const ValidateAuthFormUseCase(validator),
    enterAsGuest: EnterAsGuestUseCase(repository),
  );
}
