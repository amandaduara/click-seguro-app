import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/repositories/profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetProfileUseCase {
  GetProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<Failure, ProfileEntity>> call() => _repository.getProfile();
}
