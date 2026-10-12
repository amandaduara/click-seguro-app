import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/get_activity_progress_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/get_news_counts_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/get_profile_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/remove_avatar_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/update_avatar_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/update_profile_usecase.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/edit_profile_controller.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/profile_controller.dart';
import 'package:get_it/get_it.dart';

import '../fakes/fake_image_storage_service.dart';
import '../modules/profile/fakes/fake_profile_repository.dart';

/// O que as rotas do perfil buscam no `GetIt` (usecases e controllers), sobre
/// um [FakeProfileRepository] e um [imageStorage] (padrão: um
/// [FakeImageStorageService]). Devolve o repository usado. A
/// `UserSessionService` já precisa estar registrada quando um controller de
/// edição for criado.
FakeProfileRepository registerProfileDependencies(
  GetIt injector, {
  FakeProfileRepository? repository,
  ImageStorageService? imageStorage,
}) {
  final FakeProfileRepository fake = repository ?? FakeProfileRepository();
  injector
    ..registerSingleton(GetProfileUseCase(fake))
    ..registerSingleton(GetNewsCountsUseCase(fake))
    ..registerSingleton(GetActivityProgressUseCase(fake))
    ..registerLazySingleton(
      () => UpdateProfileUseCase(fake, injector<UserSessionService>()),
    )
    ..registerSingleton(
      UpdateAvatarUseCase(fake, imageStorage ?? FakeImageStorageService()),
    )
    ..registerSingleton(RemoveAvatarUseCase(fake))
    ..registerFactory(
      () => ProfileController(
        getProfile: injector<GetProfileUseCase>(),
        getNewsCounts: injector<GetNewsCountsUseCase>(),
        getActivityProgress: injector<GetActivityProgressUseCase>(),
      ),
    )
    ..registerFactory(
      () => EditProfileController(
        getProfile: injector<GetProfileUseCase>(),
        updateProfile: injector<UpdateProfileUseCase>(),
        updateAvatar: injector<UpdateAvatarUseCase>(),
        removeAvatar: injector<RemoveAvatarUseCase>(),
      ),
    );
  return fake;
}
