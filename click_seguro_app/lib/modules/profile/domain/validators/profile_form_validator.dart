/// Erro de um campo da edição de dados.
enum ProfileFieldError {
  nameLength,
  emailInvalid,
  emailInUse,
  phoneInvalid,
  phoneRequired,
}

/// Erros por campo; `null` = campo ok.
class ProfileFieldErrors {
  const ProfileFieldErrors({this.name, this.email, this.phone});

  final ProfileFieldError? name;
  final ProfileFieldError? email;
  final ProfileFieldError? phone;

  bool get isEmpty => name == null && email == null && phone == null;
}

/// Regras do formulário de dados (R5 de specs/012-perfil), as mesmas do
/// servidor, para nada inválido ser enviado.
abstract final class ProfileFormValidator {
  static const int nameMinLength = 6;
  static const int nameMaxLength = 150;
  static const String _countryCode = '55';
  static const Set<int> _nationalLengths = {10, 11};

  /// Mesma expressão do `CredentialsValidator` (módulo `authentication`),
  /// copiada porque um módulo não importa outro (Princípio I).
  static final RegExp _emailPattern = RegExp(
    r"^(?!\.)(?!.*\.\.)([A-Za-z0-9_'+\-\.]*)[A-Za-z0-9_+-]@([A-Za-z0-9][A-Za-z0-9\-]*\.)+[A-Za-z]{2,}$",
  );

  /// [hadPhone]: a conta já tem telefone, que não pode ser apagado (o
  /// servidor recusa, R0).
  static ProfileFieldErrors validate({
    required String name,
    required String email,
    required String phone,
    required bool hadPhone,
  }) {
    final int nameLength = name.trim().length;
    return ProfileFieldErrors(
      name: nameLength < nameMinLength || nameLength > nameMaxLength
          ? ProfileFieldError.nameLength
          : null,
      email: _emailPattern.hasMatch(email.trim())
          ? null
          : ProfileFieldError.emailInvalid,
      phone: phone.trim().isEmpty
          ? (hadPhone ? ProfileFieldError.phoneRequired : null)
          : (normalizePhone(phone) == null
                ? ProfileFieldError.phoneInvalid
                : null),
    );
  }

  /// DDD + número (10 ou 11 dígitos), com ou sem máscara e "+55", no formato
  /// do servidor: "(11) 91234-5678" → "+5511912345678". Inválido → `null`.
  static String? normalizePhone(String input) {
    String digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith(_countryCode) &&
        _nationalLengths.contains(digits.length - _countryCode.length)) {
      digits = digits.substring(_countryCode.length);
    }
    return _nationalLengths.contains(digits.length)
        ? '+$_countryCode$digits'
        : null;
  }
}
