import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/onboarding/onboarding.dart';
import 'package:click_seguro_app/modules/splash/domain/usecases/validate_stored_session_usecase.dart';
import 'package:click_seguro_app/modules/splash/presentation/controller/splash_destination.dart';
import 'package:flutter/foundation.dart';

class SplashController extends ChangeNotifier {
  SplashController(
    this._checkOnboardingSeenUseCase,
    this._validateStoredSessionUseCase,
  );

  final CheckOnboardingSeenUseCase _checkOnboardingSeenUseCase;
  final ValidateStoredSessionUseCase _validateStoredSessionUseCase;

  Future<void>? _resolving;

  SplashDestination? _destination;
  SplashDestination? get destination => _destination;

  /// Decide o destino uma única vez; chamadas seguintes reaproveitam a
  /// primeira (sem conferir nem notificar de novo).
  Future<void> resolveDestination() => _resolving ??= _resolve();

  Future<void> _resolve() async {
    // As duas conferências começam juntas; quanto a splash dura (animação e
    // espera) é decidido pela página, que conhece a animação.
    final checkResult = _checkOnboardingSeenUseCase();
    final sessionStatus = _validateStoredSessionUseCase();
    await Future.wait<void>([checkResult, sessionStatus]);

    // Falha na leitura é tratada como "não visto" (fallback seguro), em vez
    // de travar a splash.
    final bool hasSeenOnboarding = (await checkResult).fold(
      (failure) => false,
      (seen) => seen,
    );

    _destination = hasSeenOnboarding
        ? switch (await sessionStatus) {
            UserSessionStatus.authenticated ||
            UserSessionStatus.guest => SplashDestination.home,
            UserSessionStatus.unauthenticated => SplashDestination.login,
          }
        : SplashDestination.onboarding;
    notifyListeners();
  }
}
