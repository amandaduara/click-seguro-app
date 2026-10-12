import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/get_profile_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/remove_avatar_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/update_avatar_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/update_profile_usecase.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/edit_profile_controller.dart';

import '../../../fakes/fake_image_storage_service.dart';
import 'fake_profile_repository.dart';

/// `EditProfileController` com os usecases reais sobre [repository].
EditProfileController buildEditProfileController(
  FakeProfileRepository repository,
  UserSessionService session, {
  ImageStorageService? imageStorage,
}) => EditProfileController(
  getProfile: GetProfileUseCase(repository),
  updateProfile: UpdateProfileUseCase(repository, session),
  updateAvatar: UpdateAvatarUseCase(
    repository,
    imageStorage ?? FakeImageStorageService(),
  ),
  removeAvatar: RemoveAvatarUseCase(repository),
);
