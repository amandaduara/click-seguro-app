import 'package:flutter/services.dart';

const String _countryCode = '55';
const int _maxNationalDigits = 11;

/// "+5511912345678" (ou só dígitos) → "(11) 91234-5678"; incompleto fica
/// parcial: "(11) 9123".
///
/// Com [shortCodes] (contatos de confiança): até 3 dígitos fica como está
/// (190, 192) e 0800 vai em blocos ("0800 728 4567").
String formatPhone(String phone, {bool shortCodes = false}) {
  String digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length > _maxNationalDigits && digits.startsWith(_countryCode)) {
    digits = digits.substring(_countryCode.length);
  }
  if (digits.length > _maxNationalDigits) {
    digits = digits.substring(0, _maxNationalDigits);
  }
  if (digits.isEmpty) return '';
  if (shortCodes) {
    if (digits.length <= 3) return digits;
    if (digits.startsWith('0800')) return _tollFree(digits);
  }
  if (digits.length <= 2) return '($digits';
  final String area = digits.substring(0, 2);
  final String number = digits.substring(2);
  // Celular (9 dígitos) separa depois do 5º; fixo, depois do 4º.
  final int split = number.length > 8 ? 5 : 4;
  return number.length <= split
      ? '($area) $number'
      : '($area) ${number.substring(0, split)}-${number.substring(split)}';
}

/// "08007284567" → "0800 728 4567" (parcial enquanto digita).
String _tollFree(String digits) {
  final String rest = digits.substring(4);
  if (rest.isEmpty) return '0800';
  if (rest.length <= 3) return '0800 $rest';
  return '0800 ${rest.substring(0, 3)} ${rest.substring(3)}';
}

/// Máscara do campo de telefone enquanto a pessoa digita.
class PhoneInputFormatter extends TextInputFormatter {
  const PhoneInputFormatter({this.shortCodes = false});

  /// Aceita números curtos e 0800 ([formatPhone]).
  final bool shortCodes;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = formatPhone(newValue.text, shortCodes: shortCodes);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
