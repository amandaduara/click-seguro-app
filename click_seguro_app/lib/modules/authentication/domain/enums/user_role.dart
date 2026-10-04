/// Papel da conta. Só [user] pode entrar no app (FR-011).
enum UserRole {
  user,
  publisher,
  admin,
  unknown;

  /// Tolerante: valor desconhecido vira [unknown].
  static UserRole fromJson(Object? value) => switch (value) {
    'USER' => UserRole.user,
    'PUBLISHER' => UserRole.publisher,
    'ADMIN' => UserRole.admin,
    _ => UserRole.unknown,
  };
}
