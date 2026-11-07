/// Só os dígitos e o sinal `+` inicial: "(11) 9 1234-5678" → "11912345678".
/// Sem dígitos → `null`.
String? normalizePhoneNumber(String raw) {
  final trimmed = raw.trim();
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  return trimmed.startsWith('+') ? '+$digits' : digits;
}
