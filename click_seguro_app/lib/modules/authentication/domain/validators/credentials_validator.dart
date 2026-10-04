import 'package:click_seguro_app/modules/authentication/domain/enums/auth_field.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/field_error.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/password_rule.dart';

/// Regras do RN-001, as mesmas da API (ver api-contract.md). Devolve os
/// erros por campo; mapa vazio = válido.
class CredentialsValidator {
  const CredentialsValidator();

  static const int nameMinLength = 6;
  static const int nameMaxLength = 150;
  static const int emailMaxLength = 255;
  static const int passwordMinLength = 8;
  static const int passwordMaxLength = 64;
  static const int codeMinLength = 6;

  /// Mesma expressão do OpenAPI.
  static final RegExp _emailPattern = RegExp(
    r"^(?!\.)(?!.*\.\.)([A-Za-z0-9_'+\-\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\-]*\.)+[A-Za-z]{2,}$",
  );

  Map<AuthField, FieldError> validateLogin({
    required String email,
    required String password,
  }) => _result({
    AuthField.email: _emailError(email),
    AuthField.password: password.isEmpty ? FieldError.required : null,
  });

  Map<AuthField, FieldError> validateRegistration({
    required String name,
    required String email,
    required String password,
  }) => _result({
    AuthField.name: _nameError(name),
    AuthField.email: _emailError(email),
    AuthField.password: _newPasswordError(password),
  });

  Map<AuthField, FieldError> validateEmail(String email) =>
      _result({AuthField.email: _emailError(email)});

  Map<AuthField, FieldError> validateCode(String code) {
    final trimmed = code.trim();
    final FieldError? error;
    if (trimmed.isEmpty) {
      error = FieldError.required;
    } else if (trimmed.length < codeMinLength) {
      error = FieldError.codeLength;
    } else {
      error = null;
    }
    return _result({AuthField.code: error});
  }

  Map<AuthField, FieldError> validateNewPassword({
    required String password,
    required String confirmation,
  }) {
    final passwordError = _newPasswordError(password);
    return _result({
      AuthField.password: passwordError,
      AuthField.passwordConfirmation:
          passwordError == null && confirmation != password
          ? FieldError.passwordMismatch
          : null,
    });
  }

  Set<PasswordRule> passwordRules(String password) => {
    if (password.length >= passwordMinLength &&
        password.length <= passwordMaxLength)
      PasswordRule.length,
    if (password.contains(RegExp('[A-Z]'))) PasswordRule.uppercase,
    if (password.contains(RegExp('[a-z]'))) PasswordRule.lowercase,
    if (password.contains(RegExp('[0-9]'))) PasswordRule.digit,
    if (password.contains(RegExp('[^A-Za-z0-9]'))) PasswordRule.special,
  };

  FieldError? _nameError(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return FieldError.required;
    if (trimmed.length < nameMinLength || trimmed.length > nameMaxLength) {
      return FieldError.nameLength;
    }
    return null;
  }

  FieldError? _emailError(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return FieldError.required;
    if (trimmed.length > emailMaxLength || !_emailPattern.hasMatch(trimmed)) {
      return FieldError.emailInvalid;
    }
    return null;
  }

  FieldError? _newPasswordError(String password) {
    if (password.isEmpty) return FieldError.required;
    return passwordRules(password).length == PasswordRule.values.length
        ? null
        : FieldError.passwordRules;
  }

  Map<AuthField, FieldError> _result(Map<AuthField, FieldError?> errors) =>
      Map.unmodifiable({
        for (final MapEntry(:key, :value) in errors.entries) key: ?value,
      });
}
