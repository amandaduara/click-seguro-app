import 'package:click_seguro_app/modules/authentication/domain/entities/user_entity.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/user_role.dart';

/// Corpo de `GET /users/me` (GetProfileResponseDto).
class UserModel {
  const UserModel({
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    role: UserRole.fromJson(json['role']),
  );

  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;

  UserEntity toEntity() => UserEntity(
    name: name,
    email: email,
    phone: phone,
    avatarUrl: avatarUrl,
    role: role,
  );
}
