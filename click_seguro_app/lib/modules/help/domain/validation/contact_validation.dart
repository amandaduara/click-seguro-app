enum ContactValidationError { name, phone }

/// Validação pura compartilhável entre o usecase e o futuro formulário.
class ContactValidation {
  const ContactValidation._();

  static ContactValidationError? validateName(String name) =>
      name.trim().isEmpty ? ContactValidationError.name : null;

  static ContactValidationError? validatePhone(String phone) =>
      normalizePhone(phone) == null ? ContactValidationError.phone : null;

  /// Retorna telefone sem máscara ou null se a entrada não for aceita.
  static String? normalizePhone(String phone) {
    final value = phone.trim();
    if (value.isEmpty || !RegExp(r'^\+?[0-9\s().-]+$').hasMatch(value)) {
      return null;
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 3 || digits.length > 15) return null;
    return value.startsWith('+') ? '+$digits' : digits;
  }
}
