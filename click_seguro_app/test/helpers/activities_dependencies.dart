import 'package:click_seguro_app/modules/activities/domain/repositories/activities_repository.dart';
import 'package:click_seguro_app/modules/activities/domain/usecases/get_activities_dashboard_usecase.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/activities_dashboard_controller.dart';
import 'package:get_it/get_it.dart';

import '../modules/activities/fakes/fake_activities_repository.dart';

/// O que o painel de atividades busca no `GetIt` (usecase e controller),
/// sobre [repository] (padrão: o falso com os três módulos). Devolve o
/// repositório usado.
ActivitiesRepository registerActivitiesDependencies(
  GetIt injector, {
  ActivitiesRepository? repository,
}) {
  final ActivitiesRepository repo = repository ?? FakeActivitiesRepository();
  injector
    ..registerSingleton(GetActivitiesDashboardUseCase(repo))
    ..registerFactory(
      () => ActivitiesDashboardController(
        getDashboard: injector<GetActivitiesDashboardUseCase>(),
      ),
    );
  return repo;
}
