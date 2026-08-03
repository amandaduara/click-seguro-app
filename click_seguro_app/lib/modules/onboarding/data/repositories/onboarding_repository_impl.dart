import 'package:click_seguro_app/core/errors/cache_failure.dart';
import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._preferences);

  final SharedPreferences _preferences;

  static const String _onboardingSeenKey = 'onboarding_seen';

  @override
  Future<Either<Failure, bool>> hasSeenOnboarding() async {
    try {
      final bool seen = _preferences.getBool(_onboardingSeenKey) ?? false;
      return Right(seen);
    } catch (_) {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> complete() async {
    try {
      await _preferences.setBool(_onboardingSeenKey, true);
      return const Right(unit);
    } catch (_) {
      return const Left(CacheFailure());
    }
  }
}
