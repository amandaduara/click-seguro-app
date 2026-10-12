import 'package:click_seguro_app/modules/profile/domain/usecases/get_activity_progress_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/get_news_counts_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/get_profile_usecase.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/profile_controller.dart';

import 'fake_profile_repository.dart';

/// `ProfileController` com os usecases reais sobre [repository].
ProfileController buildProfileController(FakeProfileRepository repository) =>
    ProfileController(
      getProfile: GetProfileUseCase(repository),
      getNewsCounts: GetNewsCountsUseCase(repository),
      getActivityProgress: GetActivityProgressUseCase(repository),
    );
