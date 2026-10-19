import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/activities/data/datasources/guest_progress_store.dart';
import 'package:click_seguro_app/modules/activities/data/repositories/activities_repository_impl.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../fakes/activities_fixtures.dart';
import '../../fakes/fake_activities_remote_data_source.dart';

void main() {
  late UserSessionService session;
  late GuestProgressStore store;
  late FakeActivitiesRemoteDataSource remote;
  late ActivitiesRepositoryImpl repository;

  setUp(() async {
    session = UserSessionService(FakeSecureStorageService());
    await session.saveSession(
      accessToken: 'tk',
      refreshToken: 'rf',
      email: 'maria@exemplo.com',
    );
    store = GuestProgressStore(session);
    remote = FakeActivitiesRemoteDataSource();
    repository = ActivitiesRepositoryImpl(remote);
  });

  tearDown(() => store.dispose());

  test('conta: o painel do serviço', () async {
    remote.modules = dashboardJson(modules: threeModulesJson(m1: 2));

    final result = await repository.getDashboard();

    final dashboard = result.getOrElse((_) => throw StateError('falhou'));
    expect(dashboard.modules.first.completedCount, 2);
    expect(dashboard.totalCompleted, 2);
    expect(dashboard.totalAvailable, 9);
  });

  test('sem internet → ConnectionFailure', () async {
    remote.modulesError = apiError(ApiErrorType.connection);

    final result = await repository.getDashboard();

    expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
  });

  test('erro do servidor → ServerFailure', () async {
    remote.modulesError = apiError(ApiErrorType.server, statusCode: 500);

    final result = await repository.getDashboard();

    expect(result.getLeft().toNullable(), isA<ServerFailure>());
  });
}
