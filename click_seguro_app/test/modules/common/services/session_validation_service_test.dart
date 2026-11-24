import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/session_validation_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../fakes/fake_secure_storage_service.dart';
import '../api_client/fake_http_client_adapter.dart';

void main() {
  const me = {
    'name': 'Maria Silva',
    'email': 'maria@novo.com',
    'role': 'USER',
    'receiveNotifications': true,
  };

  late FakeHttpClientAdapter adapter;
  late UserSessionService session;
  late SessionValidationService validation;

  setUp(() {
    adapter = FakeHttpClientAdapter();
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    final client = ApiClient(
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
    );
    validation = SessionValidationService(
      client,
      session,
      timeout: const Duration(milliseconds: 100),
    );
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> signIn() => session.saveSession(
    accessToken: 'acesso-1',
    refreshToken: 'renovacao-1',
    email: 'maria@exemplo.com',
    userName: 'Maria',
  );

  void expectKept() {
    expect(session.sessionStatus.value, UserSessionStatus.authenticated);
    expect(session.userName, 'Maria');
  }

  test('conta confirmada atualiza nome e e-mail', () async {
    await signIn();
    adapter.body = me;

    await validation.validateStoredSession();

    expect(session.sessionStatus.value, UserSessionStatus.authenticated);
    expect(session.userName, 'Maria Silva');
    expect(session.email, 'maria@novo.com');
    expect(adapter.lastRequest!.path, SessionValidationService.mePath);
  });

  test('conta desativada deixa desconectado', () async {
    await signIn();
    adapter
      ..statusCode = 404
      ..body = {'code': 'USER_NOT_FOUND'};

    await validation.validateStoredSession();

    expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
  });

  test('renovação recusada deixa desconectado', () async {
    await signIn();
    adapter.statusCode = 401;

    await validation.validateStoredSession();

    expect(session.sessionStatus.value, UserSessionStatus.unauthenticated);
  });

  test('credencial vencida é renovada e a conta confirmada', () async {
    await signIn();
    adapter.responder = (options) {
      if (options.path == ApiClient.refreshPath) {
        return const FakeResponse(200, {
          'accessToken': 'acesso-2',
          'refreshToken': 'renovacao-2',
        });
      }
      return options.headers['Authorization'] == 'Bearer acesso-2'
          ? const FakeResponse(200, me)
          : const FakeResponse(401, {'code': 'TOKEN_INVALID'});
    };

    await validation.validateStoredSession();

    expect(session.sessionStatus.value, UserSessionStatus.authenticated);
    expect(session.accessToken, 'acesso-2');
    expect(session.userName, 'Maria Silva');
  });

  test('sem conexão mantém a sessão', () async {
    await signIn();
    adapter.error = (options) =>
        DioException.connectionError(requestOptions: options, reason: 'off');

    await validation.validateStoredSession();

    expectKept();
  });

  test('erro do servidor mantém a sessão', () async {
    await signIn();
    adapter.statusCode = 500;

    await validation.validateStoredSession();

    expectKept();
  });

  test('corpo inválido mantém a sessão sem lançar', () async {
    await signIn();
    adapter.body = {'foo': 1};

    await validation.validateStoredSession();

    expectKept();
  });

  test('prazo esgotado mantém a sessão e ignora a resposta tardia', () async {
    await signIn();
    adapter.responder = (_) =>
        const FakeResponse(200, me, Duration(seconds: 1));

    final stopwatch = Stopwatch()..start();
    await validation.validateStoredSession();
    stopwatch.stop();

    expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 500)));
    expectKept();
    expect(adapter.requests, hasLength(1));

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expectKept();
  });

  test('visitante e desconectado não chamam o serviço', () async {
    await validation.validateStoredSession();
    await session.startGuestSession();
    await validation.validateStoredSession();

    expect(adapter.requests, isEmpty);
  });
}
