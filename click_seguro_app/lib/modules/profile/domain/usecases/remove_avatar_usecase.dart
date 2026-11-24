import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/profile/domain/repositories/profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class RemoveAvatarUseCase {
  RemoveAvatarUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.removeAvatar();
}
