import 'package:click_seguro_app/core/errors/cache_failure.dart';
import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Marcação de "onboarding visto" em memória, com falhas configuráveis.
class FakeOnboardingRepository implements OnboardingRepository {
  bool seen = false;
  bool failOnRead = false;
  bool failOnComplete = false;
  int completeCalls = 0;

  @override
  Future<Either<Failure, bool>> hasSeenOnboarding() async =>
      failOnRead ? const Left(CacheFailure()) : Right(seen);

  @override
  Future<Either<Failure, Unit>> complete() async {
    completeCalls++;
    if (failOnComplete) return const Left(CacheFailure());
    seen = true;
    return const Right(unit);
  }
}
