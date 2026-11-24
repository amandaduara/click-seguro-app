import 'package:click_seguro_app/modules/authentication/data/models/auth_tokens_model.dart';
import 'package:click_seguro_app/modules/authentication/data/models/user_model.dart';

/// Endpoints de autenticação (api-contract.md). Lança `ApiException`.
abstract class AuthRemoteDataSource {
  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AuthTokensModel> login({
    required String email,
    required String password,
  });

  /// `GET /users/me` com o token recém-recebido no login.
  Future<UserModel> getMe(String accessToken);

  Future<void> forgotPassword(String email);

  Future<void> verifyCode({required String email, required String code});

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}
