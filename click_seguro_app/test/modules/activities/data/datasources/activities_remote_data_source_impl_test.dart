import 'package:click_seguro_app/modules/activities/data/datasources/activities_remote_data_source_impl.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../../common/api_client/fake_http_client_adapter.dart';
import '../../fakes/activities_fixtures.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late UserSessionService session;
  late ActivitiesRemoteDataSourceImpl dataSource;

  setUp(() {
    adapter = FakeHttpClientAdapter();
    session = UserSessionService(FakeSecureStorageService());
    GetIt.instance.registerSingleton<UserSessionService>(session);
    dataSource = ActivitiesRemoteDataSourceImpl(
      ApiClient(
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter,
      ),
    );
  });

  tearDown(() => GetIt.instance.reset());

  group('getModules', () {
    test('com conta: GET com o token e o painel lido', () async {
      await session.saveSession(
        accessToken: 'tk',
        refreshToken: 'rf',
        email: 'maria@exemplo.com',
      );
      adapter.body = dashboardJson(modules: threeModulesJson(m1: 1));

      final model = await dataSource.getModules();

      final request = adapter.lastRequest!;
      expect(request.method, 'GET');
      expect(request.path, ActivitiesRemoteDataSourceImpl.modulesPath);
      expect(request.headers['Authorization'], 'Bearer tk');
      expect(model.toEntity().modules, hasLength(3));
      expect(model.toEntity().totalCompleted, 1);
    });

    test('visitante: GET sem token', () async {
      await session.startGuestSession();
      adapter.body = dashboardJson();

      await dataSource.getModules();

      expect(
        adapter.lastRequest!.headers.containsKey('Authorization'),
        isFalse,
      );
    });
  });

  test('answerLesson: POST com a opção escolhida', () async {
    await session.saveSession(
      accessToken: 'tk',
      refreshToken: 'rf',
      email: 'maria@exemplo.com',
    );
    adapter.body = {'isCorrect': true, 'correctOptionId': 'o1'};

    await dataSource.answerLesson(
      moduleId: 'm1',
      lessonId: 'l1',
      selectedOptionId: 'o1',
    );

    final request = adapter.lastRequest!;
    expect(request.method, 'POST');
    expect(request.path, '/app/educational/modules/m1/lessons/l1/answer');
    expect(request.data, {'selectedOptionId': 'o1'});
    expect(request.headers['Authorization'], 'Bearer tk');
  });

  test('erro do serviço sobe como ApiException com o código', () async {
    adapter
      ..statusCode = 404
      ..body = {
        'statusCode': 404,
        'code': 'EDUCATIONAL_LESSON_NOT_FOUND',
        'message': 'Lesson not found',
      };

    await expectLater(
      dataSource.answerLesson(
        moduleId: 'm1',
        lessonId: 'l9',
        selectedOptionId: 'o1',
      ),
      throwsA(
        isA<ApiException>()
            .having((e) => e.type, 'type', ApiErrorType.client)
            .having(
              (e) => e.errorCode,
              'errorCode',
              'EDUCATIONAL_LESSON_NOT_FOUND',
            ),
      ),
    );
  });
}
