import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/common/validators/password_policy.dart';

/// Textos da lista de regras da senha, no cadastro, na recuperação e na
/// troca de senha.
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
