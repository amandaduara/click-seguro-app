import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:fpdart/fpdart.dart';

class CheckOnboardingSeenUseCase {
  CheckOnboardingSeenUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<Either<Failure, bool>> call() {
    return _repository.hasSeenOnboarding();
  }
}
