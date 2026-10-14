import 'package:click_seguro_app/modules/profile/data/models/activity_progress_model.dart';
import 'package:click_seguro_app/modules/profile/data/models/profile_model.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/news_counts_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_update.dart';

/// Dados da conta para o perfil. Erros sobem como `ApiException`.
abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile();

  /// Totais de lidas, salvas e curtidas, pedidos ao mesmo tempo.
  Future<NewsCountsEntity> getNewsCounts();

  Future<ActivityProgressModel> getActivityProgress();

  /// Envia só os campos preenchidos de [update].
  Future<void> updateProfile(ProfileUpdate update);

  /// Envia a foto em [filePath] e devolve a nova `avatarUrl`.
  Future<String> uploadAvatar(String filePath);

  Future<void> removeAvatar();
}
