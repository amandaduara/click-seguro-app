import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/settings/data/datasources/account_remote_data_source.dart';
import 'package:click_seguro_app/modules/settings/data/models/account_summary_model.dart';

/// Datasource próprio: não importa `profile` nem `authentication` (R1 de
/// specs/013-configuracoes).
class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  AccountRemoteDataSourceImpl(this._apiClient);

  static const String mePath = '/users/me';
  static const String changePasswordPath = '/users/me/change-password';
  static const String loginPath = '/auth/app/login';

  final ApiClient _apiClient;

  @override
  Future<AccountSummaryModel> getAccount() async {
    final response = await _apiClient.get(mePath);
    return response.toModel(AccountSummaryModel.fromJson);
  }

  @override
  Future<void> setReceiveAlerts(bool value) async {
    await _apiClient.patch(mePath, data: {'receiveNotifications': value});
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.patch(
      changePasswordPath,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  @override
  Future<({String accessToken, String refreshToken})> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      loginPath,
      data: {'email': email, 'password': password},
      requiresAuth: false,
    );
    return response.toModel(
      (json) => (
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      ),
    );
  }
}
