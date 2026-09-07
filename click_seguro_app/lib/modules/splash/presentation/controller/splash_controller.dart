import 'package:click_seguro_app/modules/onboarding/domain/usecases/check_onboarding_seen_usecase.dart';
import 'package:flutter/foundation.dart';

class SplashController extends ChangeNotifier {
  SplashController(this._checkOnboardingSeenUseCase);

  static const Duration minimumDisplayDuration = Duration(seconds: 2);

  final CheckOnboardingSeenUseCase _checkOnboardingSeenUseCase;

  String? _destinationRoute;
  String? get destinationRoute => _destinationRoute;

  Future<void> resolveDestination() async {
    final delay = Future<void>.delayed(minimumDisplayDuration);
    final checkResult = await _checkOnboardingSeenUseCase();
    await delay;

    // Falha na leitura é tratada como "não visto" (fallback seguro exigido
    // por specs/app-splash/spec.md), em vez de travar a splash.
    final bool hasSeenOnboarding = checkResult.fold(
      (failure) => false,
      (seen) => seen,
    );

    _destinationRoute = hasSeenOnboarding ? '/login' : '/onboarding';
    notifyListeners();
  }
}
