import 'package:click_seguro_app/modules/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:click_seguro_app/modules/authentication/data/models/auth_tokens_model.dart';
import 'package:click_seguro_app/modules/authentication/data/models/user_model.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._apiClient);

  static const String registerPath = '/auth/app/register';
  static const String loginPath = '/auth/app/login';
  static const String mePath = '/users/me';
  static const String forgotPasswordPath = '/auth/forgot-password';
  static const String verifyCodePath = '/auth/forgot-password/verify';
  static const String resetPasswordPath = '/auth/forgot-password/reset';

  final ApiClient _apiClient;

  @override
  Future<AuthTokensModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      loginPath,
      data: {'email': email, 'password': password},
      requiresAuth: false,
    );
    return response.toModel(AuthTokensModel.fromJson);
  }

  @override
  Future<UserModel> getMe(String accessToken) async {
    final response = await _apiClient.get(mePath, authToken: accessToken);
    return response.toModel(UserModel.fromJson);
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _apiClient.post(
      registerPath,
      data: {'name': name, 'email': email, 'password': password},
      requiresAuth: false,
    );
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _apiClient.post(
      forgotPasswordPath,
      data: {'email': email},
      requiresAuth: false,
    );
  }

  @override
  Future<void> verifyCode({required String email, required String code}) async {
    await _apiClient.post(
      verifyCodePath,
      data: {'email': email, 'code': code},
      requiresAuth: false,
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _apiClient.post(
      resetPasswordPath,
      data: {'email': email, 'code': code, 'newPassword': newPassword},
      requiresAuth: false,
    );
  }
}
