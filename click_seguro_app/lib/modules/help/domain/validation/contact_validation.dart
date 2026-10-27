import 'package:click_seguro_app/core/utils/phone_number.dart';

enum ContactValidationError { name, phone }

/// Validação pura do contato, usada pelo usecase de salvar.
class ContactValidation {
  const ContactValidation._();

  static ContactValidationError? validateName(String name) =>
      name.trim().isEmpty ? ContactValidationError.name : null;

  /// Retorna telefone sem máscara ou null se a entrada não for aceita.
  static String? normalizePhone(String phone) {
    final value = phone.trim();
    if (!RegExp(r'^\+?[0-9\s().-]+$').hasMatch(value)) return null;
    final normalized = normalizePhoneNumber(value);
    if (normalized == null) return null;
    final digits = normalized.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 3 && digits.length <= 15 ? normalized : null;
  }
}
