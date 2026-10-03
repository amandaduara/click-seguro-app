import 'dart:async';

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

  Future<void> signIn() => session.saveSession(
    accessToken: 'acesso-1',
    refreshToken: 'renovacao-1',
    email: 'maria@exemplo.com',
  );

  Matcher apiException(ApiErrorType type, {int? statusCode}) {
    return throwsA(
      isA<ApiException>()
          .having((e) => e.type, 'type', type)
          .having((e) => e.statusCode, 'statusCode', statusCode),
    );
  }

  group('requisição', () {
    test('envia o Bearer token quando requiresAuth = true', () async {
      await signIn();

      await client.get('/news');

      expect(adapter.lastRequest!.headers['Authorization'], 'Bearer acesso-1');
    });

    test('não envia Authorization quando requiresAuth = false', () async {
      await signIn();

      await client.post('/login', requiresAuth: false);

      expect(
        adapter.lastRequest!.headers.containsKey('Authorization'),
        isFalse,
      );
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
      await signIn();
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

    test(
      '401 sem sessão (senha errada no login) não gera aviso de expirada',
      () async {
        adapter
          ..statusCode = 401
          ..body = {'code': 'INVALID_CREDENTIALS'};

        await expectLater(
          client.post('/auth/login', requiresAuth: false),
          apiException(ApiErrorType.unauthorized, statusCode: 401),
        );
        expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
        expect(session.endReason, isNull);
      },
    );

    test('4xx vira client e expõe code/message do corpo', () async {
      adapter
        ..statusCode = 409
        ..body = {'code': 'ALREADY_REPORTED', 'message': 'Já denunciada'};

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

  group('F0.2 código de erro', () {
    test('lê o código de negócio do campo code', () async {
      adapter
        ..statusCode = 409
        ..body = {
          'code': 'USER_EMAIL_ALREADY_EXISTS',
          'message': 'Email already registered',
        };

      await expectLater(
        client.post('/auth/app/register', requiresAuth: false),
        throwsA(
          isA<ApiException>().having(
            (e) => e.errorCode,
            'errorCode',
            'USER_EMAIL_ALREADY_EXISTS',
          ),
        ),
      );
    });

    test('formato antigo com error não vira errorCode', () async {
      adapter
        ..statusCode = 409
        ..body = {'error': 'X', 'message': 'm'};

      await expectLater(
        client.post('/x'),
        throwsA(
          isA<ApiException>().having((e) => e.errorCode, 'errorCode', isNull),
        ),
      );
    });
  });

  group('F0.2 cancelamento', () {
    test('get cancelado vira cancelled sem mexer na sessão', () async {
      await signIn();
      adapter.responder = (_) =>
          const FakeResponse(200, {}, Duration(seconds: 1));
      final cancelToken = CancelToken();

      final request = client.get('/app/news', cancelToken: cancelToken);
      cancelToken.cancel();

      await expectLater(request, apiException(ApiErrorType.cancelled));
      expect(
        adapter.requests.where((r) => r.path == '/auth/app/refresh'),
        isEmpty,
      );
      expect(session.sessionStatus.value, UserSessionStatus.authenticated);
    });
  });

  group('US1 renovação', () {
    const protectedPath = '/users/me/news/saved';
    const newPair = {'accessToken': 'acesso-2', 'refreshToken': 'renovacao-2'};

    late FutureOr<FakeResponse> Function(RequestOptions options) onRefresh;

    int callsTo(String path) =>
        adapter.requests.where((r) => r.path == path).length;

    setUp(() {
      onRefresh = (_) => const FakeResponse(200, newPair);
      // Servidor falso: só aceita o access token renovado.
      adapter.responder = (options) {
        if (options.path == ApiClient.refreshPath) return onRefresh(options);
        return options.headers['Authorization'] == 'Bearer acesso-2'
            ? const FakeResponse(200, {'ok': true})
            : const FakeResponse(401, {'code': 'TOKEN_INVALID'});
      };
    });

    test('renova, repete o pedido e guarda o novo par', () async {
      await signIn();

      final response = await client.get(protectedPath);

      expect(response.statusCode, 200);
      expect(session.accessToken, 'acesso-2');
      expect(session.refreshToken, 'renovacao-2');
      expect(session.sessionStatus.value, UserSessionStatus.authenticated);
      final refresh = adapter.requests.singleWhere(
        (r) => r.path == ApiClient.refreshPath,
      );
      expect(refresh.method, 'POST');
      expect(refresh.data, {'refreshToken': 'renovacao-1'});
      expect(refresh.headers.containsKey('Authorization'), isFalse);
    });

    test('renovação recusada encerra a sessão como expirada', () async {
      await signIn();
      onRefresh = (_) => const FakeResponse(401, {'code': 'TOKEN_INVALID'});

      await expectLater(
        client.get(protectedPath),
        apiException(ApiErrorType.unauthorized, statusCode: 401),
      );
      expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
      expect(session.endReason, SessionEndReason.expired);
    });

    test(
      'renovação sem conexão mantém a sessão e devolve connection',
      () async {
        await signIn();
        onRefresh = (options) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'offline',
        );

        await expectLater(
          client.get(protectedPath),
          apiException(ApiErrorType.connection),
        );
        expect(session.sessionStatus.value, UserSessionStatus.authenticated);
        expect(session.accessToken, 'acesso-1');
      },
    );

    test('renovação com 500 mantém a sessão e devolve server', () async {
      await signIn();
      onRefresh = (_) => const FakeResponse(500, {'message': 'boom'});

      await expectLater(
        client.get(protectedPath),
        apiException(ApiErrorType.server, statusCode: 500),
      );
      expect(session.sessionStatus.value, UserSessionStatus.authenticated);
    });

    test('401 no pedido repetido expira sem renovar de novo', () async {
      await signIn();
      adapter.responder = (options) => options.path == ApiClient.refreshPath
          ? const FakeResponse(200, newPair)
          : const FakeResponse(401, {'code': 'TOKEN_INVALID'});

      await expectLater(
        client.get(protectedPath),
        apiException(ApiErrorType.unauthorized, statusCode: 401),
      );
      expect(callsTo(ApiClient.refreshPath), 1);
      expect(callsTo(protectedPath), 2);
      expect(session.endReason, SessionEndReason.expired);
    });

    test('5 pedidos recusados juntos compartilham uma renovação', () async {
      await signIn();
      onRefresh = (_) =>
          const FakeResponse(200, newPair, Duration(milliseconds: 50));

      final responses = await Future.wait([
        for (var i = 0; i < 5; i++) client.get('/r/$i'),
      ]);

      expect(responses.map((r) => r.statusCode), everyElement(200));
      expect(callsTo(ApiClient.refreshPath), 1);
    });

    test('token já trocado por outra renovação: só repete', () async {
      await signIn();
      var first = true;
      adapter.responder = (options) async {
        if (options.path == ApiClient.refreshPath) {
          return const FakeResponse(200, newPair);
        }
        if (first) {
          first = false;
          // Outra renovação terminou enquanto este pedido voava.
          await session.replaceTokens(
            previousRefreshToken: 'renovacao-1',
            accessToken: 'acesso-2',
            refreshToken: 'renovacao-2',
          );
          return const FakeResponse(401, {'code': 'TOKEN_INVALID'});
        }
        return options.headers['Authorization'] == 'Bearer acesso-2'
            ? const FakeResponse(200, {'ok': true})
            : const FakeResponse(401, {'code': 'TOKEN_INVALID'});
      };

      final response = await client.get(protectedPath);

      expect(response.statusCode, 200);
      expect(callsTo(ApiClient.refreshPath), 0);
      expect(callsTo(protectedPath), 2);
    });

    test('logout durante a renovação: não repete nem reconecta', () async {
      await signIn();
      onRefresh = (_) async {
        await session.logout();
        return const FakeResponse(200, newPair);
      };

      await expectLater(
        client.get(protectedPath),
        apiException(ApiErrorType.unauthorized, statusCode: 401),
      );
      expect(callsTo(protectedPath), 1);
      expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
      expect(session.endReason, SessionEndReason.userLogout);
      expect(session.accessToken, isNull);
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

      expect(response.toModelList((json) => json['id'] as String), ['1', '2']);
    });

    test('corpo em formato inesperado vira invalidResponse', () async {
      adapter.body = [
        {'id': 1},
      ];

      final response = await client.get('/news');

      expect(
        () => response.toModelList((json) => json['id'] as String),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            ApiErrorType.invalidResponse,
          ),
        ),
      );
    });
  });
}
