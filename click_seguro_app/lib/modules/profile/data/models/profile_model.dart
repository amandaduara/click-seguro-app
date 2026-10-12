import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';

/// `GET /users/me` (R0 de specs/012-perfil).
class ProfileModel {
  const ProfileModel({
    required this.name,
    required this.email,
    required this.receiveNotifications,
    this.phone,
    this.avatarUrl,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final avatarUrl = json['avatarUrl'] as String?;
    return ProfileModel(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      avatarUrl: avatarUrl == null || avatarUrl.isEmpty ? null : avatarUrl,
      receiveNotifications: json['receiveNotifications'] as bool? ?? true,
    );
  }

  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final bool receiveNotifications;

  ProfileEntity toEntity() => ProfileEntity(
    name: name,
    email: email,
    phone: phone,
    avatarUrl: avatarUrl,
    receiveNotifications: receiveNotifications,
  );
}
