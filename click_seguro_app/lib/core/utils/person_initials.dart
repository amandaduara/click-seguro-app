/// Iniciais da primeira e da última palavra de um nome.
String personInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.first.isEmpty) return '';
  final first = String.fromCharCode(words.first.runes.first);
  if (words.length == 1 || words.last.isEmpty) return first.toUpperCase();
  final last = String.fromCharCode(words.last.runes.first);
  return '$first$last'.toUpperCase();
}
