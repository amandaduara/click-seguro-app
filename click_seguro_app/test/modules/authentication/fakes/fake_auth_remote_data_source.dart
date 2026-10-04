import 'package:click_seguro_app/modules/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:click_seguro_app/modules/authentication/data/models/auth_tokens_model.dart';
import 'package:click_seguro_app/modules/authentication/data/models/user_model.dart';
import 'package:click_seguro_app/modules/authentication/domain/enums/user_role.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';

ApiException apiError(
  ApiErrorType type, {
  int? statusCode,
  String? errorCode,
}) => ApiException(
  type: type,
  statusCode: statusCode,
  errorCode: errorCode,
  message: 'falha simulada',
);

/// Datasource falso: cada método devolve o valor configurado ou lança o
/// `ApiException` configurado, e conta as chamadas.
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  AuthTokensModel tokens = const AuthTokensModel(
    accessToken: 'acesso-1',
    refreshToken: 'renovacao-1',
  );
  UserModel me = const UserModel(
    name: 'Maria Silva',
    email: 'maria@exemplo.com',
    role: UserRole.user,
  );

  ApiException? registerError;
  ApiException? loginError;
  ApiException? getMeError;
  ApiException? forgotError;
  ApiException? verifyError;
  ApiException? resetError;

  final List<String> calls = [];
  String? lastMeToken;

  void _run(String name, ApiException? error) {
    calls.add(name);
    if (error != null) throw error;
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async => _run('register', registerError);

  @override
  Future<AuthTokensModel> login({
    required String email,
    required String password,
  }) async {
    _run('login', loginError);
    return tokens;
  }

  @override
  Future<UserModel> getMe(String accessToken) async {
    lastMeToken = accessToken;
    _run('getMe', getMeError);
    return me;
  }

  @override
  Future<void> forgotPassword(String email) async =>
      _run('forgotPassword', forgotError);

  @override
  Future<void> verifyCode({
    required String email,
    required String code,
  }) async => _run('verifyCode', verifyError);

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async => _run('resetPassword', resetError);
}
