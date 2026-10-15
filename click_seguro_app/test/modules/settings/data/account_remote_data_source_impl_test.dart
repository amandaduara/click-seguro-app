import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/settings/data/datasources/account_remote_data_source_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../fakes/fake_secure_storage_service.dart';
import '../../common/api_client/fake_http_client_adapter.dart';
import '../fakes/settings_fixtures.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late AccountRemoteDataSourceImpl dataSource;

  setUp(() async {
    adapter = FakeHttpClientAdapter();
    final session = UserSessionService(FakeSecureStorageService());
    await session.saveSession(
      accessToken: 'acesso-1',
      refreshToken: 'renovacao-1',
      email: 'maria@exemplo.com',
    );
    GetIt.instance.registerSingleton<UserSessionService>(session);
    dataSource = AccountRemoteDataSourceImpl(
      ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter,
      ),
    );
  });

  tearDown(() => GetIt.instance.reset());

  test('getAccount: GET /users/me', () async {
    adapter.body = accountJson(receiveNotifications: false);

    final account = await dataSource.getAccount();

    expect(adapter.lastRequest!.method, 'GET');
    expect(adapter.lastRequest!.path, AccountRemoteDataSourceImpl.mePath);
    final entity = account.toEntity();
    expect(entity.name, 'Maria da Silva');
    expect(entity.receiveNotifications, isFalse);
  });

  test(
    'setReceiveAlerts: PATCH /users/me só com receiveNotifications',
    () async {
      adapter.statusCode = 204;

      await dataSource.setReceiveAlerts(false);

      final request = adapter.lastRequest!;
      expect(request.method, 'PATCH');
      expect(request.path, AccountRemoteDataSourceImpl.mePath);
      expect(request.data, {'receiveNotifications': false});
    },
  );

  test('changePassword: PATCH /users/me/change-password', () async {
    adapter.statusCode = 204;

    await dataSource.changePassword(
      currentPassword: 'Senha@123',
      newPassword: 'NovaSenha@456',
    );

    final request = adapter.lastRequest!;
    expect(request.method, 'PATCH');
    expect(request.path, AccountRemoteDataSourceImpl.changePasswordPath);
    expect(request.data, {
      'currentPassword': 'Senha@123',
      'newPassword': 'NovaSenha@456',
    });
  });

  test(
    'login: POST /auth/app/login sem Authorization e devolve o par',
    () async {
      adapter.body = tokensJson();

      final tokens = await dataSource.login(
        email: 'maria@exemplo.com',
        password: 'NovaSenha@456',
      );

      final request = adapter.lastRequest!;
      expect(request.method, 'POST');
      expect(request.path, AccountRemoteDataSourceImpl.loginPath);
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(request.data, {
        'email': 'maria@exemplo.com',
        'password': 'NovaSenha@456',
      });
      expect(tokens, (
        accessToken: 'acesso-novo',
        refreshToken: 'renovacao-nova',
      ));
    },
  );

  for (final (status, code) in [
    (401, 'INVALID_CREDENTIALS'),
    (409, 'USER_NEW_PASSWORD_EQUALS_OLD'),
  ]) {
    test('$status $code sobe como ApiException com o errorCode', () async {
      adapter
        ..statusCode = status
        ..body = {'code': code, 'message': 'recusado'};

      await expectLater(
        dataSource.changePassword(
          currentPassword: 'Senha@123',
          newPassword: 'NovaSenha@456',
        ),
        throwsA(
          isA<ApiException>().having((e) => e.errorCode, 'errorCode', code),
        ),
      );
    });
  }
}
