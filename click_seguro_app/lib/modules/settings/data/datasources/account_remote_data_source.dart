import 'package:click_seguro_app/modules/settings/data/models/account_summary_model.dart';

/// Conta nas Configurações. Erros sobem como `ApiException`.
abstract class AccountRemoteDataSource {
  Future<AccountSummaryModel> getAccount();

  Future<void> setReceiveAlerts(bool value);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Entra de novo depois da troca de senha (R0 de specs/013).
  Future<({String accessToken, String refreshToken})> login({
    required String email,
    required String password,
  });
}
