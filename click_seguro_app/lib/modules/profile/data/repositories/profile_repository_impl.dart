import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/api_client/api_failure_mapper.dart';
import 'package:click_seguro_app/modules/profile/data/datasources/profile_remote_data_source.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/activity_progress_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/news_counts_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_update.dart';
import 'package:click_seguro_app/modules/profile/domain/failures/profile_failures.dart';
import 'package:click_seguro_app/modules/profile/domain/repositories/profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote);

  static const String emailInUseCode = 'USER_EMAIL_ALREADY_EXISTS';
  static const String invalidImageCode = 'INVALID_IMAGE_TYPE';

  final ProfileRemoteDataSource _remote;

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() =>
      _guard(() async => (await _remote.getProfile()).toEntity());

  @override
  Future<Either<Failure, NewsCountsEntity>> getNewsCounts() =>
      _guard(_remote.getNewsCounts);

  @override
  Future<Either<Failure, ActivityProgressEntity>> getActivityProgress() =>
      _guard(() async => (await _remote.getActivityProgress()).toEntity());

  /// O 500 que o servidor devolve para qualquer troca de e-mail (R0) cai no
  /// mapeamento padrão: falha genérica.
  @override
  Future<Either<Failure, Unit>> updateProfile(ProfileUpdate update) =>
      _guard(() async {
        await _remote.updateProfile(update);
        return unit;
      }, specific: {emailInUseCode: const EmailInUseFailure()});

  @override
  Future<Either<Failure, String>> uploadAvatar(String filePath) => _guard(
    () => _remote.uploadAvatar(filePath),
    specific: {invalidImageCode: const AvatarTypeFailure()},
  );

  @override
  Future<Either<Failure, Unit>> removeAvatar() => _guard(() async {
    await _remote.removeAvatar();
    return unit;
  });

  /// [specific]: falha por `errorCode`, antes do mapeamento padrão.
  Future<Either<Failure, T>> _guard<T>(
    Future<T> Function() action, {
    Map<String, Failure> specific = const {},
  }) async {
    try {
      return Right(await action());
    } on ApiException catch (e) {
      return Left(specific[e.errorCode] ?? e.toFailure());
    }
  }
}
