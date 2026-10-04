import 'package:click_seguro_app/modules/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:click_seguro_app/modules/authentication/data/models/auth_tokens_model.dart';
import 'package:click_seguro_app/modules/authentication/data/models/user_model.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._apiClient);

  static const String registerPath = '/auth/app/register';
  static const String loginPath = '/auth/app/login';
  static const String mePath = '/users/me';

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
  Future<void> forgotPassword(String email) => throw UnimplementedError('US4');

  @override
  Future<void> verifyCode({required String email, required String code}) =>
      throw UnimplementedError('US4');

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => throw UnimplementedError('US4');
}
