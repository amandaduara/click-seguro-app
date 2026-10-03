import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/api_client/redacting_log_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_http_client_adapter.dart';

void main() {
  late List<String> lines;
  late FakeHttpClientAdapter adapter;
  late Dio dio;

  setUp(() {
    lines = [];
    adapter = FakeHttpClientAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        RedactingLogInterceptor(
          sensitivePathPrefixes: ApiClient.sensitivePathPrefixes,
          logPrint: (line) => lines.add(line.toString()),
        ),
      );
  });

  String log() => lines.join('\n');

  test('renovação: tokens fora do log, caminho e status registrados', () async {
    adapter.body = {'accessToken': 'acesso-2', 'refreshToken': 'renovacao-2'};

    await dio.post(
      ApiClient.refreshPath,
      data: {'refreshToken': 'renovacao-1'},
    );

    expect(log(), isNot(contains('renovacao-1')));
    expect(log(), isNot(contains('acesso-2')));
    expect(log(), isNot(contains('renovacao-2')));
    expect(log(), contains(ApiClient.refreshPath));
    expect(log(), contains('200'));
  });

  test('login: senha fora do log', () async {
    await dio.post(
      '/auth/app/login',
      data: {'email': 'maria@exemplo.com', 'password': 'Senha@123'},
    );

    expect(log(), isNot(contains('Senha@123')));
  });

  test('erro em rota sensível não registra o corpo', () async {
    adapter
      ..statusCode = 401
      ..body = {'code': 'INVALID_CREDENTIALS', 'message': 'segredo-do-corpo'};

    await expectLater(
      dio.patch(
        '/users/me/change-password',
        data: {'currentPassword': 'Antiga@123', 'newPassword': 'Nova@1234'},
      ),
      throwsA(isA<DioException>()),
    );

    expect(log(), isNot(contains('Antiga@123')));
    expect(log(), isNot(contains('Nova@1234')));
    expect(log(), isNot(contains('segredo-do-corpo')));
    expect(log(), contains('401'));
  });

  test('rota comum registra o corpo da resposta', () async {
    adapter.body = {'titulo': 'Golpe do Pix'};

    await dio.get('/app/news');

    expect(log(), contains('Golpe do Pix'));
  });

  test('nenhum header Authorization é registrado', () async {
    await dio.get(
      '/app/news',
      options: Options(headers: {'Authorization': 'Bearer acesso-1'}),
    );

    expect(log(), isNot(contains('acesso-1')));
  });
}
