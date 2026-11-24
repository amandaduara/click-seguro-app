import 'package:click_seguro_app/modules/settings/domain/entities/account_summary_entity.dart';

/// `GET /users/me`: só o que as Configurações usam.
class AccountSummaryModel {
  const AccountSummaryModel({
    required this.name,
    required this.receiveNotifications,
    this.avatarUrl,
  });

  factory AccountSummaryModel.fromJson(Map<String, dynamic> json) {
    final avatarUrl = json['avatarUrl'] as String?;
    return AccountSummaryModel(
      name: json['name'] as String,
      avatarUrl: avatarUrl == null || avatarUrl.isEmpty ? null : avatarUrl,
      receiveNotifications: json['receiveNotifications'] as bool? ?? true,
    );
  }

  final String name;
  final String? avatarUrl;
  final bool receiveNotifications;

  AccountSummaryEntity toEntity() => AccountSummaryEntity(
    name: name,
    avatarUrl: avatarUrl,
    receiveNotifications: receiveNotifications,
  );
}
