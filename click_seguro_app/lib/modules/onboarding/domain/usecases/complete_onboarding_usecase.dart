import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:fpdart/fpdart.dart';

class CompleteOnboardingUseCase {
  CompleteOnboardingUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<Either<Failure, Unit>> call() {
    return _repository.complete();
  }
}
