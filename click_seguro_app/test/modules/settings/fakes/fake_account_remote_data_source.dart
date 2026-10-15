import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/settings/data/datasources/account_remote_data_source.dart';
import 'package:click_seguro_app/modules/settings/data/models/account_summary_model.dart';

import 'settings_fixtures.dart';

/// Datasource em memória com um erro opcional por método.
class FakeAccountRemoteDataSource implements AccountRemoteDataSource {
  ApiException? accountError;
  ApiException? alertsError;
  ApiException? changeError;
  ApiException? loginError;

  AccountSummaryModel account = AccountSummaryModel.fromJson(accountJson());

  final List<bool> alertsCalls = [];
  final List<({String current, String newPassword})> changeCalls = [];
  final List<({String email, String password})> loginCalls = [];

  @override
  Future<AccountSummaryModel> getAccount() async {
    if (accountError != null) throw accountError!;
    return account;
  }

  @override
  Future<void> setReceiveAlerts(bool value) async {
    alertsCalls.add(value);
    if (alertsError != null) throw alertsError!;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changeCalls.add((current: currentPassword, newPassword: newPassword));
    if (changeError != null) throw changeError!;
  }

  @override
  Future<({String accessToken, String refreshToken})> login({
    required String email,
    required String password,
  }) async {
    loginCalls.add((email: email, password: password));
    if (loginError != null) throw loginError!;
    return (accessToken: 'acesso-novo', refreshToken: 'renovacao-nova');
  }
}
