import 'package:click_seguro_app/modules/common/services/session_validation_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';

/// Confere a conta da sessão salva na abertura do app (delega à feature 002)
/// e devolve o estado da sessão **depois** da conferência. Nunca lança.
class ValidateStoredSessionUseCase {
  ValidateStoredSessionUseCase(this._validation, this._session);

  final SessionValidationService _validation;
  final UserSessionService _session;

  Future<UserSessionStatus> call() async {
    try {
      await _validation.validateStoredSession();
    } catch (_) {
      // O serviço já não lança; isto só impede que um erro inesperado prenda
      // o splash (FR-008 de specs/004-splash-onboarding-sessao).
    }
    return _session.sessionStatus.value;
  }
}
