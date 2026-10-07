import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/news/data/datasources/news_remote_data_source_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../common/api_client/fake_http_client_adapter.dart';
import '../../fakes/news_fixtures.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late UserSessionService session;
  late NewsRemoteDataSourceImpl dataSource;

  setUp(() {
    adapter = FakeHttpClientAdapter();
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    dataSource = NewsRemoteDataSourceImpl(
      ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter,
      ),
    );
  });

  tearDown(() => GetIt.instance.reset());

  test('getFeed pede por página, sem cursor', () async {
    adapter.body = feedJson(recent: newsItemsJson(1));

    final json = await dataSource.getFeed(page: 2);

    final request = adapter.lastRequest!;
    expect(request.path, NewsRemoteDataSourceImpl.feedPath);
    expect(request.queryParameters, {'page': 2, 'limit': 20});
    expect(json['recent'], isA<Map<String, dynamic>>());
  });

  test('getReels pede os 10 primeiros', () async {
    adapter.body = reelsJson(items: [reelItemJson(id: 'r1')]);

    final json = await dataSource.getReels();

    final request = adapter.lastRequest!;
    expect(request.path, NewsRemoteDataSourceImpl.reelsPath);
    expect(request.queryParameters, {'limit': 10});
    expect(json['data'], hasLength(1));
  });

  group('getNews', () {
    test('com categoria e busca, ordenado do mais novo', () async {
      adapter.body = newsListJson(items: newsItemsJson(1));

      final list = await dataSource.getNews(
        page: 1,
        category: 'phishing',
        search: 'pix',
      );

      final request = adapter.lastRequest!;
      expect(request.path, NewsRemoteDataSourceImpl.newsPath);
      expect(request.queryParameters, {
        'page': 1,
        'limit': 20,
        'category': 'phishing',
        'search': 'pix',
        'sortBy': 'publishedAt',
        'sortOrder': 'desc',
      });
      expect(list.items.single.id, 'n1');
    });

    test('sem categoria nem busca, não envia esses parâmetros', () async {
      adapter.body = newsListJson();

      await dataSource.getNews(page: 2);

      expect(adapter.lastRequest!.queryParameters, {
        'page': 2,
        'limit': 20,
        'sortBy': 'publishedAt',
        'sortOrder': 'desc',
      });
    });

    test('uma nova consulta cancela a anterior', () async {
      adapter.responder = (options) => FakeResponse(
        200,
        newsListJson(),
        options.queryParameters['search'] == 'pi'
            ? const Duration(seconds: 1)
            : Duration.zero,
      );

      final first = dataSource.getNews(page: 1, search: 'pi');
      final second = dataSource.getNews(page: 1, search: 'pix');

      await expectLater(
        first,
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            ApiErrorType.cancelled,
          ),
        ),
      );
      expect((await second).items, isEmpty);
    });
  });

  test('getCategories devolve só as ativas', () async {
    adapter.body = categoriesJson;

    final categories = await dataSource.getCategories();

    expect(adapter.lastRequest!.path, NewsRemoteDataSourceImpl.categoriesPath);
    expect(categories.map((c) => c.slug), ['phishing', 'golpes-bancarios']);
  });

  group('credencial', () {
    test('visitante não envia Authorization', () async {
      adapter.body = feedJson();
      await session.startGuestSession();

      await dataSource.getFeed(page: 1);

      expect(
        adapter.lastRequest!.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('conectada envia o Bearer', () async {
      adapter.body = feedJson();
      await session.saveSession(
        accessToken: 'acesso-1',
        refreshToken: 'renovacao-1',
        email: 'maria@exemplo.com',
        userName: 'Maria',
      );

      await dataSource.getFeed(page: 1);

      expect(adapter.lastRequest!.headers['Authorization'], 'Bearer acesso-1');
    });
  });

  group('erros', () {
    test('500 vira ApiException(server)', () async {
      adapter
        ..statusCode = 500
        ..body = {'code': 'INTERNAL', 'message': 'x'};

      await expectLater(
        dataSource.getFeed(page: 1),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            ApiErrorType.server,
          ),
        ),
      );
    });

    test('corpo inválido vira ApiException(invalidResponse)', () async {
      adapter.body = ['não é um objeto'];

      await expectLater(
        dataSource.getNews(page: 1),
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
