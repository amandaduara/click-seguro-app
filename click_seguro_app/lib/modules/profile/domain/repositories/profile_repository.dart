import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/activity_progress_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/news_counts_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_update.dart';
import 'package:fpdart/fpdart.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileEntity>> getProfile();

  Future<Either<Failure, NewsCountsEntity>> getNewsCounts();

  Future<Either<Failure, ActivityProgressEntity>> getActivityProgress();

  Future<Either<Failure, Unit>> updateProfile(ProfileUpdate update);

  /// `Right` com a nova `avatarUrl`.
  Future<Either<Failure, String>> uploadAvatar(String filePath);

  Future<Either<Failure, Unit>> removeAvatar();
}
