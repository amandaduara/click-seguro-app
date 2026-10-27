import 'dart:async';

import 'package:click_seguro_app/modules/activities/data/datasources/activities_remote_data_source.dart';
import 'package:click_seguro_app/modules/activities/data/datasources/activities_remote_data_source_impl.dart';
import 'package:click_seguro_app/modules/activities/data/datasources/guest_progress_store.dart';
import 'package:click_seguro_app/modules/activities/data/repositories/activities_repository_impl.dart';
import 'package:click_seguro_app/modules/activities/domain/repositories/activities_repository.dart';
import 'package:click_seguro_app/modules/activities/domain/usecases/get_activities_dashboard_usecase.dart';
import 'package:click_seguro_app/modules/activities/domain/usecases/get_module_detail_usecase.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/activities_dashboard_controller.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/lesson_controller.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/single_child_widget.dart';

/// Atividades (B1–B4). O registro do visitante é um só por execução do app:
/// é a "sessão atual" da RN-006 (R3 de specs/015-painel-atividades).
class ActivitiesModule implements ModuleInterface {
  @override
  FutureOr<void> registerServices(GetIt injector) {
    injector
      ..registerLazySingleton<ActivitiesRemoteDataSource>(
        () => ActivitiesRemoteDataSourceImpl(injector<ApiClient>()),
      )
      ..registerLazySingleton<GuestProgressStore>(
        () => GuestProgressStore(injector<UserSessionService>()),
        dispose: (store) => store.dispose(),
      )
      ..registerLazySingleton<ActivitiesRepository>(
        () => ActivitiesRepositoryImpl(
          injector<ActivitiesRemoteDataSource>(),
          injector<GuestProgressStore>(),
          injector<UserSessionService>(),
        ),
      )
      ..registerLazySingleton(
        () => GetActivitiesDashboardUseCase(injector<ActivitiesRepository>()),
      )
      ..registerLazySingleton(
        () => GetModuleDetailUseCase(injector<ActivitiesRepository>()),
      )
      ..registerFactory(
        () => LessonController(
          getModuleDetail: injector<GetModuleDetailUseCase>(),
        ),
      )
      ..registerFactory(
        () => ActivitiesDashboardController(
          getDashboard: injector<GetActivitiesDashboardUseCase>(),
        ),
      );
  }

  @override
  List<SingleChildWidget> providers(GetIt injector) => [];
}
