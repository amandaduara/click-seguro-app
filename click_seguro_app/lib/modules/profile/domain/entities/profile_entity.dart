import 'package:click_seguro_app/core/utils/person_initials.dart';

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
  String get initials => personInitials(name);

  /// O mesmo perfil com outra foto (ou sem foto).
  ProfileEntity withAvatarUrl(String? avatarUrl) => ProfileEntity(
    name: name,
    email: email,
    phone: phone,
    avatarUrl: avatarUrl,
    receiveNotifications: receiveNotifications,
  );
}
