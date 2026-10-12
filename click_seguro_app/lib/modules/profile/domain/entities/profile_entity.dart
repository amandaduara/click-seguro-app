/// Dados da conta de `GET /users/me`.
class ProfileEntity {
  const ProfileEntity({
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.receiveNotifications = true,
  });

  final String name;
  final String email;

  /// No formato `+55` + DDD + número.
  final String? phone;
  final String? avatarUrl;
  final bool receiveNotifications;

  /// Iniciais da primeira e da última palavra do nome (sem foto).
  String get initials {
    final List<String> words = name.trim().split(RegExp(r'\s+'));
    if (words.first.isEmpty) return '';
    final String first = words.first[0];
    return (words.length == 1 ? first : first + words.last[0]).toUpperCase();
  }
}
