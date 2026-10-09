import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/notifications/data/datasources/alerts_local_data_source.dart';
import 'package:click_seguro_app/modules/notifications/data/datasources/alerts_local_data_source_impl.dart';
import 'package:click_seguro_app/modules/notifications/data/datasources/alerts_remote_data_source.dart';
import 'package:click_seguro_app/modules/notifications/data/models/alert_model.dart';
import 'package:click_seguro_app/modules/notifications/data/models/alerts_snapshot_model.dart';
import 'package:click_seguro_app/modules/notifications/domain/repositories/notifications_repository.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/check_new_alerts_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/clear_alerts_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/get_alerts_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/mark_all_as_read_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/mark_as_read_usecase.dart';
import 'package:click_seguro_app/modules/notifications/notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../fakes/fake_local_cache_service.dart';
import '../../fakes/fake_secure_storage_service.dart';
import 'fakes/alerts_fixtures.dart';

void main() {
  late UserSessionService session;
  late FakeLocalCacheService cache;
  final injector = GetIt.instance;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    cache = FakeLocalCacheService();
    injector
      ..registerSingleton<UserSessionService>(session)
      ..registerSingleton<LocalCacheService>(cache)
      ..registerSingleton<ApiClient>(ApiClient());
    await NotificationsModule().registerServices(injector);
  });

  tearDown(() async => injector.reset());

  test('registra datasources, repository e os cinco use cases', () {
    expect(injector<AlertsRemoteDataSource>(), isNotNull);
    expect(injector<AlertsLocalDataSource>(), isNotNull);
    expect(injector<NotificationsRepository>(), isNotNull);
    expect(injector<CheckNewAlertsUseCase>(), isNotNull);
    expect(injector<GetAlertsUseCase>(), isNotNull);
    expect(injector<MarkAsReadUseCase>(), isNotNull);
    expect(injector<MarkAllAsReadUseCase>(), isNotNull);
    expect(injector<ClearAlertsUseCase>(), isNotNull);
  });

  test('o dono do registro é o e-mail da sessão (visitante: guest)', () async {
    final local = injector<AlertsLocalDataSource>();
    final model = AlertsSnapshotModel(alerts: [AlertModel.fromEntity(alert())]);

    await local.write(model);
    expect(cache.values[AlertsLocalDataSourceImpl.cacheKey]!['owner'], 'guest');

    await session.saveSession(
      accessToken: 'tk',
      refreshToken: 'rf',
      email: 'ana@test.com',
    );
    expect(await local.read(), isNull);
    await local.write(model);
    expect(
      cache.values[AlertsLocalDataSourceImpl.cacheKey]!['owner'],
      'ana@test.com',
    );
  });
}
