import 'package:click_seguro_app/modules/activities/domain/repositories/activities_repository.dart';
import 'package:click_seguro_app/modules/activities/domain/usecases/answer_lesson_usecase.dart';
import 'package:click_seguro_app/modules/activities/domain/usecases/get_activities_dashboard_usecase.dart';
import 'package:click_seguro_app/modules/activities/domain/usecases/get_module_detail_usecase.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/activities_dashboard_controller.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/lesson_controller.dart';
import 'package:get_it/get_it.dart';

import '../modules/activities/fakes/fake_activities_repository.dart';

/// O que o painel e as perguntas das atividades buscam no `GetIt`
/// (usecases e controllers), sobre [repository] (padrão: o falso com os três
/// módulos). Devolve o repositório usado. A voz das perguntas vem de
/// `registerNewsDetailDependencies` ou do próprio teste.
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
    )
    ..registerSingleton(GetModuleDetailUseCase(repo))
    ..registerSingleton(AnswerLessonUseCase(repo))
    ..registerFactory(
      () => LessonController(
        getModuleDetail: injector<GetModuleDetailUseCase>(),
        answerLesson: injector<AnswerLessonUseCase>(),
      ),
    );
  return repo;
}
