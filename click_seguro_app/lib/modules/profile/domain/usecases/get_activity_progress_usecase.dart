import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/activity_progress_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/repositories/profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetActivityProgressUseCase {
  GetActivityProgressUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<Failure, ActivityProgressEntity>> call() =>
      _repository.getActivityProgress();
}
