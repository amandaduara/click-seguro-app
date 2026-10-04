import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/field_error.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/password_rule.dart';

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

extension PasswordRulePresentation on PasswordRule {
  /// Chave de tradução do texto da regra na lista de regras da senha.
  String get labelKey => switch (this) {
    PasswordRule.length => AppStrings.authRuleLength,
    PasswordRule.uppercase => AppStrings.authRuleUppercase,
    PasswordRule.lowercase => AppStrings.authRuleLowercase,
    PasswordRule.digit => AppStrings.authRuleDigit,
    PasswordRule.special => AppStrings.authRuleSpecial,
  };
}
