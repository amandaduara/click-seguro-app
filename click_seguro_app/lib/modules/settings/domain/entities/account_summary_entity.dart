/// O que as Configurações mostram da conta (`GET /users/me`).
class AccountSummaryEntity {
  const AccountSummaryEntity({
    required this.name,
    required this.receiveNotifications,
    this.avatarUrl,
  });

  final String name;
  final String? avatarUrl;
  final bool receiveNotifications;

  /// Iniciais da primeira e da última palavra do nome (sem foto).
  String get initials => initialsOf(name);

  AccountSummaryEntity withReceiveNotifications(bool value) =>
      AccountSummaryEntity(
        name: name,
        avatarUrl: avatarUrl,
        receiveNotifications: value,
      );
}

/// Iniciais da primeira e da última palavra de [name].
String initialsOf(String name) {
  final List<String> words = name.trim().split(RegExp(r'\s+'));
  if (words.first.isEmpty) return '';
  final String first = words.first[0];
  return (words.length == 1 ? first : first + words.last[0]).toUpperCase();
}
