import 'package:click_seguro_app/modules/activities/activities.dart';
import 'package:click_seguro_app/modules/activities/data/datasources/activities_remote_data_source.dart';
import 'package:click_seguro_app/modules/activities/data/datasources/guest_progress_store.dart';
import 'package:click_seguro_app/modules/activities/domain/repositories/activities_repository.dart';
import 'package:click_seguro_app/modules/activities/domain/usecases/get_activities_dashboard_usecase.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../fakes/fake_secure_storage_service.dart';

void main() {
  setUp(() async {
    GetIt.instance
      ..registerSingleton<UserSessionService>(
        UserSessionService(FakeSecureStorageService()),
      )
      ..registerSingleton<ApiClient>(ApiClient(dio: Dio()));
    await ActivitiesModule().registerServices(GetIt.instance);
  });

  tearDown(() async => GetIt.instance.reset());

  test('registra datasource, registro, repositório e usecase', () {
    final GetIt injector = GetIt.instance;

    expect(injector<ActivitiesRemoteDataSource>(), isNotNull);
    expect(injector<ActivitiesRepository>(), isNotNull);
    expect(injector<GetActivitiesDashboardUseCase>(), isNotNull);
  });

  test('o registro do visitante é um só por execução', () {
    expect(
      identical(
        GetIt.instance<GuestProgressStore>(),
        GetIt.instance<GuestProgressStore>(),
      ),
      isTrue,
    );
  });
}
