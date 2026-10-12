import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/get_profile_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/update_profile_usecase.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/edit_profile_controller.dart';

import 'fake_profile_repository.dart';

/// `EditProfileController` com os usecases reais sobre [repository].
EditProfileController buildEditProfileController(
  FakeProfileRepository repository,
  UserSessionService session,
) => EditProfileController(
  getProfile: GetProfileUseCase(repository),
  updateProfile: UpdateProfileUseCase(repository, session),
);
