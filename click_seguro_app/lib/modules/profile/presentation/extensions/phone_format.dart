import 'package:flutter/services.dart';

const String _countryCode = '55';
const int _maxNationalDigits = 11;

/// "+5511912345678" (ou só dígitos) → "(11) 91234-5678"; incompleto fica
/// parcial: "(11) 9123".
String formatPhone(String phone) {
  String digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length > _maxNationalDigits && digits.startsWith(_countryCode)) {
    digits = digits.substring(_countryCode.length);
  }
  if (digits.length > _maxNationalDigits) {
    digits = digits.substring(0, _maxNationalDigits);
  }
  if (digits.isEmpty) return '';
  if (digits.length <= 2) return '($digits';
  final String area = digits.substring(0, 2);
  final String number = digits.substring(2);
  // Celular (9 dígitos) separa depois do 5º; fixo, depois do 4º.
  final int split = number.length > 8 ? 5 : 4;
  return number.length <= split
      ? '($area) $number'
      : '($area) ${number.substring(0, split)}-${number.substring(split)}';
}

/// Máscara do campo de telefone enquanto a pessoa digita.
class PhoneInputFormatter extends TextInputFormatter {
  const PhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = formatPhone(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
