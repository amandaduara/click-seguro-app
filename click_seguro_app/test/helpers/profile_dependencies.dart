import 'package:click_seguro_app/modules/profile/domain/usecases/get_activity_progress_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/get_news_counts_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/get_profile_usecase.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/profile_controller.dart';
import 'package:get_it/get_it.dart';

import '../modules/profile/fakes/fake_profile_repository.dart';

/// O que as rotas do perfil buscam no `GetIt` (usecases e controllers), sobre
/// um [FakeProfileRepository]. Devolve o repository usado.
FakeProfileRepository registerProfileDependencies(
  GetIt injector, {
  FakeProfileRepository? repository,
}) {
  final FakeProfileRepository fake = repository ?? FakeProfileRepository();
  injector
    ..registerSingleton(GetProfileUseCase(fake))
    ..registerSingleton(GetNewsCountsUseCase(fake))
    ..registerSingleton(GetActivityProgressUseCase(fake))
    ..registerFactory(
      () => ProfileController(
        getProfile: injector<GetProfileUseCase>(),
        getNewsCounts: injector<GetNewsCountsUseCase>(),
        getActivityProgress: injector<GetActivityProgressUseCase>(),
      ),
    );
  return fake;
}
