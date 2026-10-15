import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/field_error.dart';

extension FieldErrorPresentation on FieldError {
  /// Chave de tradução da mensagem exibida sob o campo.
  String get messageKey => switch (this) {
    FieldError.required => AppStrings.authFieldRequired,
    FieldError.nameLength => AppStrings.authFieldNameLength,
    FieldError.emailInvalid => AppStrings.authFieldEmailInvalid,
    FieldError.passwordRules => AppStrings.authFieldPasswordRules,
    FieldError.passwordMismatch => AppStrings.authFieldPasswordMismatch,
    FieldError.codeLength => AppStrings.authFieldCodeLength,
  };
}
