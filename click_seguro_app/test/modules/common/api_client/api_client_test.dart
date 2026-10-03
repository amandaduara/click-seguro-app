import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../fakes/fake_secure_storage_service.dart';
import 'fake_http_client_adapter.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late UserSessionService session;
  late ApiClient client;

  setUp(() {
    adapter = FakeHttpClientAdapter();
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    client = ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
    );
  });

  tearDown(() => GetIt.instance.reset());

  Matcher apiException(ApiErrorType type, {int? statusCode}) {
    return throwsA(
      isA<ApiException>()
          .having((e) => e.type, 'type', type)
          .having((e) => e.statusCode, 'statusCode', statusCode),
    );
  }

  group('requisição', () {
    test('envia o Bearer token quando requiresAuth = true', () async {
      await session.saveSession(token: 'abc', userId: 'u1');

      await client.get('/news');

      expect(adapter.lastRequest!.headers['Authorization'], 'Bearer abc');
    });

    test('não envia Authorization quando requiresAuth = false', () async {
      await session.saveSession(token: 'abc', userId: 'u1');

      await client.post('/login', requiresAuth: false);

      expect(adapter.lastRequest!.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('mapeamento de erro', () {
    test('falha de conexão vira ApiErrorType.connection', () {
      adapter.error = (options) => DioException.connectionError(
            requestOptions: options,
            reason: 'offline',
          );

      expect(client.get('/news'), apiException(ApiErrorType.connection));
    });

    test('timeout de recebimento vira ApiErrorType.timeout', () {
      adapter.error = (options) => DioException.receiveTimeout(
            timeout: const Duration(seconds: 10),
            requestOptions: options,
          );

      expect(client.get('/news'), apiException(ApiErrorType.timeout));
    });

    test('401 com sessão conectada encerra a sessão como expirada', () async {
      await session.saveSession(token: 'abc', userId: 'u1');
      adapter
        ..statusCode = 401
        ..body = {'message': 'Token expirado'};

      await expectLater(
        client.get('/news'),
        apiException(ApiErrorType.unauthorized, statusCode: 401),
      );
      expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
      expect(session.endReason, SessionEndReason.expired);
    });

    test('401 sem sessão (senha errada no login) não gera aviso de expirada',
        () async {
      adapter
        ..statusCode = 401
        ..body = {'error': 'INVALID_CREDENTIALS'};

      await expectLater(
        client.post('/auth/login', requiresAuth: false),
        apiException(ApiErrorType.unauthorized, statusCode: 401),
      );
      expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
      expect(session.endReason, isNull);
    });

    test('4xx vira client e expõe error/message do corpo', () async {
      adapter
        ..statusCode = 409
        ..body = {'error': 'ALREADY_REPORTED', 'message': 'Já denunciada'};

      await expectLater(
        client.post('/reports'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.type, 'type', ApiErrorType.client)
              .having((e) => e.statusCode, 'statusCode', 409)
              .having((e) => e.errorCode, 'errorCode', 'ALREADY_REPORTED')
              .having((e) => e.message, 'message', 'Já denunciada'),
        ),
      );
    });

    test('5xx com corpo não-JSON vira server sem quebrar o parse', () {
      adapter
        ..statusCode = 502
        ..body = '<html>Bad Gateway</html>';

      expect(
        client.get('/news'),
        apiException(ApiErrorType.server, statusCode: 502),
      );
    });
  });

  group('ApiResponseMapper', () {
    test('toModel converte o corpo em modelo', () async {
      adapter.body = {'id': '1'};

      final response = await client.get('/news/1');

      expect(response.toModel((json) => json['id'] as String), '1');
    });

    test('toModelList converte um array na raiz', () async {
      adapter.body = [
        {'id': '1'},
        {'id': '2'},
      ];

      final response = await client.get('/news');

      expect(
        response.toModelList((json) => json['id'] as String),
        ['1', '2'],
      );
    });

    test('corpo em formato inesperado vira invalidResponse', () async {
      adapter.body = [
        {'id': 1},
      ];

      final response = await client.get('/news');

      expect(
        () => response.toModelList((json) => json['id'] as String),
        throwsA(
          isA<ApiException>()
              .having((e) => e.type, 'type', ApiErrorType.invalidResponse),
        ),
      );
    });
  });
}
