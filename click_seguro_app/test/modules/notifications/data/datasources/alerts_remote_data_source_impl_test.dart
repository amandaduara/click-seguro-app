import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/notifications/data/datasources/alerts_remote_data_source_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../common/api_client/fake_http_client_adapter.dart';
import '../../fakes/alerts_fixtures.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late AlertsRemoteDataSourceImpl dataSource;
  final since = DateTime.utc(2026, 10, 9, 15);

  setUp(() {
    adapter = FakeHttpClientAdapter();
    GetIt.instance.registerSingleton<UserSessionService>(
      UserSessionService(FakeSecureStorageService()),
    );
    dataSource = AlertsRemoteDataSourceImpl(
      ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter,
      ),
    );
  });

  tearDown(() => GetIt.instance.reset());

  group('fetchNewAlerts', () {
    test('GET /app/news com startDate em UTC, ordem e limite', () async {
      adapter.body = newsListJson([newsItemJson(id: 'n1')]);

      await dataSource.fetchNewAlerts(since: since, limit: 50);

      final request = adapter.lastRequest!;
      expect(request.method, 'GET');
      expect(request.path, AlertsRemoteDataSourceImpl.newsPath);
      expect(request.queryParameters, {
        'startDate': '2026-10-09T15:00:00.000Z',
        'sortBy': 'publishedAt',
        'sortOrder': 'desc',
        'limit': 50,
        'page': 1,
      });
    });

    test('since em horário local vai em UTC', () async {
      adapter.body = newsListJson(const []);

      await dataSource.fetchNewAlerts(
        since: DateTime.parse('2026-10-09T12:00:00.000-03:00'),
        limit: 50,
      );

      expect(
        adapter.lastRequest!.queryParameters['startDate'],
        '2026-10-09T15:00:00.000Z',
      );
    });

    test('devolve os itens válidos, na ordem', () async {
      adapter.body = newsListJson([realBankNewsJson, realPixNewsJson]);

      final alerts = await dataSource.fetchNewAlerts(since: since, limit: 50);

      expect(alerts.map((a) => a.newsId), [
        'cmuywjppz0001fo1slem3p1zr',
        'cmuywmr7p000nfo1sucepkjy5',
      ]);
      expect(alerts.every((a) => !a.isRead), isTrue);
    });

    test('ignora o item sem título (CB-005)', () async {
      adapter.body = newsListJson([
        newsItemJson(id: 'bom'),
        newsItemJson(id: 'ruim')..remove('title'),
        newsItemJson(id: 'bom2'),
      ]);

      final alerts = await dataSource.fetchNewAlerts(since: since, limit: 50);

      expect(alerts.map((a) => a.newsId), ['bom', 'bom2']);
    });

    test('ignora o item que não é objeto', () async {
      adapter.body = {
        'data': [newsItemJson(id: 'bom'), 'texto', 7],
      };

      final alerts = await dataSource.fetchNewAlerts(since: since, limit: 50);

      expect(alerts.single.newsId, 'bom');
    });

    test('sem itens: lista vazia', () async {
      adapter.body = newsListJson(const []);

      expect(await dataSource.fetchNewAlerts(since: since, limit: 50), isEmpty);
    });

    test('data ausente: resposta inválida', () async {
      adapter.body = {'meta': <String, dynamic>{}};

      await expectLater(
        dataSource.fetchNewAlerts(since: since, limit: 50),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            ApiErrorType.invalidResponse,
          ),
        ),
      );
    });

    test('data que não é lista: resposta inválida', () async {
      adapter.body = {'data': 'nada'};

      await expectLater(
        dataSource.fetchNewAlerts(since: since, limit: 50),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            ApiErrorType.invalidResponse,
          ),
        ),
      );
    });

    test('sem conexão: ApiException de conexão', () async {
      adapter.error = (options) => DioException.connectionError(
        requestOptions: options,
        reason: 'sem rede',
      );

      await expectLater(
        dataSource.fetchNewAlerts(since: since, limit: 50),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            ApiErrorType.connection,
          ),
        ),
      );
    });

    test('tempo esgotado: ApiException de timeout', () async {
      adapter.error = (options) => DioException.receiveTimeout(
        timeout: const Duration(seconds: 60),
        requestOptions: options,
      );

      await expectLater(
        dataSource.fetchNewAlerts(since: since, limit: 50),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            ApiErrorType.timeout,
          ),
        ),
      );
    });
  });

  group('getReceiveAlerts', () {
    test('GET /users/me e lê receiveNotifications', () async {
      adapter.body = profileJson(receiveNotifications: false);

      final value = await dataSource.getReceiveAlerts();

      expect(adapter.lastRequest!.method, 'GET');
      expect(adapter.lastRequest!.path, AlertsRemoteDataSourceImpl.mePath);
      expect(value, isFalse);
    });

    test('true no servidor', () async {
      adapter.body = profileJson(receiveNotifications: true);

      expect(await dataSource.getReceiveAlerts(), isTrue);
    });

    test('campo ausente: true (padrão da API)', () async {
      adapter.body = profileJson();

      expect(await dataSource.getReceiveAlerts(), isTrue);
    });

    test('sem conexão: ApiException de conexão', () async {
      adapter.error = (options) => DioException.connectionError(
        requestOptions: options,
        reason: 'sem rede',
      );

      await expectLater(
        dataSource.getReceiveAlerts(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            ApiErrorType.connection,
          ),
        ),
      );
    });

    test('tempo esgotado: ApiException de timeout', () async {
      adapter.error = (options) => DioException.connectionTimeout(
        timeout: const Duration(seconds: 10),
        requestOptions: options,
      );

      await expectLater(
        dataSource.getReceiveAlerts(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            ApiErrorType.timeout,
          ),
        ),
      );
    });
  });
}
