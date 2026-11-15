import 'package:click_seguro_app/core/utils/phone_number.dart';

enum ContactValidationError { name, phone }

/// Validação pura do contato, usada pelo usecase de salvar.
class ContactValidation {
  const ContactValidation._();

  /// Tamanho máximo do nome do contato.
  static const int nameMaxLength = 60;

  /// Nome obrigatório e com até [nameMaxLength] caracteres.
  static ContactValidationError? validateName(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty || trimmed.length > nameMaxLength
        ? ContactValidationError.name
        : null;
  }

  /// Retorna telefone sem máscara ou null se a entrada não for aceita.
  ///
  /// Número completo (validação da usuária, specs/024): curto de 3 dígitos
  /// (190), 0800 com 11 dígitos, fixo ou celular com DDD (10 ou 11 dígitos)
  /// ou internacional com `+` (8 a 15 dígitos).
  static String? normalizePhone(String phone) {
    final value = phone.trim();
    if (!RegExp(r'^\+?[0-9\s().-]+$').hasMatch(value)) return null;
    final normalized = normalizePhoneNumber(value);
    if (normalized == null) return null;
    final digits = normalized.replaceAll(RegExp(r'\D'), '');
    final bool complete = normalized.startsWith('+')
        ? digits.length >= 8 && digits.length <= 15
        : digits.length == 3 || digits.length == 10 || digits.length == 11;
    return complete ? normalized : null;
  }
}
