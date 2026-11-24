import 'package:click_seguro_app/modules/authentication/domain/enums/user_role.dart';

class UserEntity {
  const UserEntity({
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
  });

  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
}
