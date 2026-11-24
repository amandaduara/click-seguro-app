import 'package:click_seguro_app/modules/common/services/session_validation_service.dart';

/// Conferência da conta sem rede: [onValidate] simula o efeito na sessão
/// (atualizar o perfil, encerrar, lançar ou esperar um `Completer`).
class FakeSessionValidationService implements SessionValidationService {
  FakeSessionValidationService({this.onValidate});

  Future<void> Function()? onValidate;

  int calls = 0;

  @override
  Future<void> validateStoredSession() async {
    calls++;
    await onValidate?.call();
  }
}
