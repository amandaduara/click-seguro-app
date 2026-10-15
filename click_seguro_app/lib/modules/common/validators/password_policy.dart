/// Regras da senha (RN-001), iguais às da API.
enum PasswordRule { length, uppercase, lowercase, digit, special }

/// Política de senha do RN-001, usada no cadastro, na recuperação
/// (`authentication`) e na troca de senha (`settings`). Espaços contam como
/// caracteres: nada é removido.
abstract final class PasswordPolicy {
  static const int minLength = 8;
  static const int maxLength = 64;

  static Set<PasswordRule> rulesMet(String password) => {
    if (password.length >= minLength && password.length <= maxLength)
      PasswordRule.length,
    if (password.contains(RegExp('[A-Z]'))) PasswordRule.uppercase,
    if (password.contains(RegExp('[a-z]'))) PasswordRule.lowercase,
    if (password.contains(RegExp('[0-9]'))) PasswordRule.digit,
    if (password.contains(RegExp('[^A-Za-z0-9]'))) PasswordRule.special,
  };

  static bool isValid(String password) =>
      rulesMet(password).length == PasswordRule.values.length;
}
