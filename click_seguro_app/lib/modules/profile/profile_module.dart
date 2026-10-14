import 'dart:async';

import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/profile/data/datasources/profile_remote_data_source.dart';
import 'package:click_seguro_app/modules/profile/data/datasources/profile_remote_data_source_impl.dart';
import 'package:click_seguro_app/modules/profile/data/repositories/profile_repository_impl.dart';
import 'package:click_seguro_app/modules/profile/domain/repositories/profile_repository.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/get_activity_progress_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/get_news_counts_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/get_profile_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/remove_avatar_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/update_avatar_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/update_profile_usecase.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/edit_profile_controller.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/profile_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/single_child_widget.dart';

class ProfileModule implements ModuleInterface {
  @override
  FutureOr<void> registerServices(GetIt injector) {
    injector
      ..registerLazySingleton<ProfileRemoteDataSource>(
        () => ProfileRemoteDataSourceImpl(injector<ApiClient>()),
      )
      ..registerLazySingleton<ProfileRepository>(
        () => ProfileRepositoryImpl(injector<ProfileRemoteDataSource>()),
      )
      ..registerLazySingleton(
        () => GetProfileUseCase(injector<ProfileRepository>()),
      )
      ..registerLazySingleton(
        () => GetNewsCountsUseCase(injector<ProfileRepository>()),
      )
      ..registerLazySingleton(
        () => GetActivityProgressUseCase(injector<ProfileRepository>()),
      )
      ..registerLazySingleton(
        () => UpdateProfileUseCase(
          injector<ProfileRepository>(),
          injector<UserSessionService>(),
        ),
      )
      ..registerLazySingleton(
        () => UpdateAvatarUseCase(
          injector<ProfileRepository>(),
          injector<ImageStorageService>(),
        ),
      )
      ..registerLazySingleton(
        () => RemoveAvatarUseCase(injector<ProfileRepository>()),
      )
      // Uma por tela: a aba e a lista de conquistas aberta por link direto.
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
  }

  @override
  List<SingleChildWidget> providers(GetIt injector) => [];
}
