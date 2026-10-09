import 'dart:async';

import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/notifications/data/datasources/alerts_local_data_source.dart';
import 'package:click_seguro_app/modules/notifications/data/datasources/alerts_local_data_source_impl.dart';
import 'package:click_seguro_app/modules/notifications/data/datasources/alerts_remote_data_source.dart';
import 'package:click_seguro_app/modules/notifications/data/datasources/alerts_remote_data_source_impl.dart';
import 'package:click_seguro_app/modules/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:click_seguro_app/modules/notifications/domain/repositories/notifications_repository.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/check_new_alerts_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/clear_alerts_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/get_alerts_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/mark_all_as_read_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/mark_as_read_usecase.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/single_child_widget.dart';

class NotificationsModule implements ModuleInterface {
  @override
  FutureOr<void> registerServices(GetIt injector) {
    injector
      ..registerLazySingleton<AlertsRemoteDataSource>(
        () => AlertsRemoteDataSourceImpl(injector<ApiClient>()),
      )
      ..registerLazySingleton<AlertsLocalDataSource>(
        () => AlertsLocalDataSourceImpl(
          injector<LocalCacheService>(),
          owner: () => injector<UserSessionService>().email ?? 'guest',
        ),
      )
      ..registerLazySingleton<NotificationsRepository>(
        () => NotificationsRepositoryImpl(
          injector<AlertsRemoteDataSource>(),
          injector<AlertsLocalDataSource>(),
        ),
      )
      ..registerLazySingleton(
        () => CheckNewAlertsUseCase(injector<NotificationsRepository>()),
      )
      ..registerLazySingleton(
        () => GetAlertsUseCase(injector<NotificationsRepository>()),
      )
      ..registerLazySingleton(
        () => MarkAsReadUseCase(injector<NotificationsRepository>()),
      )
      ..registerLazySingleton(
        () => MarkAllAsReadUseCase(injector<NotificationsRepository>()),
      )
      ..registerLazySingleton(
        () => ClearAlertsUseCase(injector<NotificationsRepository>()),
      );
  }

  /// Os providers (controller e gatilho) entram na US1.
  @override
  List<SingleChildWidget> providers(GetIt injector) => [];
}
