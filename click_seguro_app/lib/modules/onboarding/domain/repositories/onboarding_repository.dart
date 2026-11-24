import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:fpdart/fpdart.dart';

abstract class OnboardingRepository {
  Future<Either<Failure, bool>> hasSeenOnboarding();
  Future<Either<Failure, Unit>> complete();
}
