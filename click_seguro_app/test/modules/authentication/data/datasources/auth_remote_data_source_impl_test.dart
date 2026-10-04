import 'package:click_seguro_app/modules/authentication/data/datasources/auth_remote_data_source_impl.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../common/api_client/fake_http_client_adapter.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    adapter = FakeHttpClientAdapter();
    GetIt.instance.registerSingleton<UserSessionService>(
      UserSessionService(FakeSecureStorageService()),
    );
    dataSource = AuthRemoteDataSourceImpl(
      ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter,
      ),
    );
  });

  tearDown(() => GetIt.instance.reset());

  group('login', () {
    test('POST /auth/app/login sem Authorization devolve os tokens', () async {
      adapter.body = {'accessToken': 'acesso-1', 'refreshToken': 'renovacao-1'};

      final tokens = await dataSource.login(
        email: 'maria@exemplo.com',
        password: 'Senha@123',
      );

      final request = adapter.lastRequest!;
      expect(request.method, 'POST');
      expect(request.path, AuthRemoteDataSourceImpl.loginPath);
      expect(request.data, {
        'email': 'maria@exemplo.com',
        'password': 'Senha@123',
      });
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(tokens.accessToken, 'acesso-1');
      expect(tokens.refreshToken, 'renovacao-1');
    });

    test('getMe usa o token informado', () async {
      adapter.body = {
        'name': 'Maria Silva',
        'email': 'maria@exemplo.com',
        'role': 'USER',
        'receiveNotifications': true,
      };

      final user = await dataSource.getMe('acesso-1');

      final request = adapter.lastRequest!;
      expect(request.method, 'GET');
      expect(request.path, AuthRemoteDataSourceImpl.mePath);
      expect(request.headers['Authorization'], 'Bearer acesso-1');
      expect(user.name, 'Maria Silva');
    });

    test('senha errada vira ApiException com INVALID_CREDENTIALS', () async {
      adapter
        ..statusCode = 401
        ..body = {'code': 'INVALID_CREDENTIALS', 'message': 'Invalid'};

      await expectLater(
        dataSource.login(email: 'maria@exemplo.com', password: 'x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.type, 'type', ApiErrorType.unauthorized)
              .having((e) => e.errorCode, 'errorCode', 'INVALID_CREDENTIALS'),
        ),
      );
    });
  });

  group('register', () {
    test('POST /auth/app/register sem Authorization', () async {
      adapter
        ..statusCode = 201
        ..body = {'name': 'Maria Silva', 'email': 'maria@exemplo.com'};

      await dataSource.register(
        name: 'Maria Silva',
        email: 'maria@exemplo.com',
        password: 'Senha@123',
      );

      final request = adapter.lastRequest!;
      expect(request.method, 'POST');
      expect(request.path, AuthRemoteDataSourceImpl.registerPath);
      expect(request.data, {
        'name': 'Maria Silva',
        'email': 'maria@exemplo.com',
        'password': 'Senha@123',
      });
      expect(request.headers.containsKey('Authorization'), isFalse);
    });

    test('e-mail duplicado vira ApiException com o código', () async {
      adapter
        ..statusCode = 409
        ..body = {'code': 'USER_EMAIL_ALREADY_EXISTS', 'message': 'dup'};

      await expectLater(
        dataSource.register(
          name: 'Maria Silva',
          email: 'maria@exemplo.com',
          password: 'Senha@123',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.errorCode,
            'errorCode',
            'USER_EMAIL_ALREADY_EXISTS',
          ),
        ),
      );
    });
  });

  group('recuperação', () {
    test(
      'os três passos usam os caminhos e corpos certos, sem token',
      () async {
        adapter.statusCode = 204;

        await dataSource.forgotPassword('maria@exemplo.com');
        await dataSource.verifyCode(email: 'maria@exemplo.com', code: '123456');
        await dataSource.resetPassword(
          email: 'maria@exemplo.com',
          code: '123456',
          newPassword: 'Nova@1234',
        );

        final requests = adapter.requests;
        expect(requests.map((r) => r.path), [
          AuthRemoteDataSourceImpl.forgotPasswordPath,
          AuthRemoteDataSourceImpl.verifyCodePath,
          AuthRemoteDataSourceImpl.resetPasswordPath,
        ]);
        expect(requests.map((r) => r.method), everyElement('POST'));
        expect(requests[0].data, {'email': 'maria@exemplo.com'});
        expect(requests[1].data, {
          'email': 'maria@exemplo.com',
          'code': '123456',
        });
        expect(requests[2].data, {
          'email': 'maria@exemplo.com',
          'code': '123456',
          'newPassword': 'Nova@1234',
        });
        expect(
          requests.every((r) => !r.headers.containsKey('Authorization')),
          isTrue,
        );
      },
    );
  });
}
