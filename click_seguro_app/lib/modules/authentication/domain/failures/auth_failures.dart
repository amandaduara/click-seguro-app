import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/auth_field.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/field_error.dart';

/// Validação local falhou; nada foi enviado ao serviço (SC-004).
class InvalidFormFailure extends Failure {
  InvalidFormFailure(Map<AuthField, FieldError> fieldErrors)
    : fieldErrors = Map.unmodifiable(fieldErrors),
      super(AppStrings.authErrorInvalidForm);

  final Map<AuthField, FieldError> fieldErrors;
}

/// E-mail ou senha incorretos, ou conta que não é de usuário do app.
class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure()
    : super(AppStrings.authErrorInvalidCredentials);
}

class EmailAlreadyExistsFailure extends Failure {
  const EmailAlreadyExistsFailure() : super(AppStrings.authErrorEmailExists);
}

/// A conta foi criada, mas a entrada automática falhou (FR-009).
class AccountCreatedFailure extends Failure {
  const AccountCreatedFailure() : super(AppStrings.authInfoAccountCreated);
}

class InvalidRecoveryCodeFailure extends Failure {
  const InvalidRecoveryCodeFailure() : super(AppStrings.authErrorInvalidCode);
}
