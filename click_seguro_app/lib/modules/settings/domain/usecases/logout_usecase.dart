import 'package:click_seguro_app/modules/common/services/user_session_service.dart';

/// Sai da conta (R2 de specs/013): só a sessão acaba; contatos, fotos e
/// preferências do aparelho ficam (RN-007). O roteador leva ao login.
class LogoutUseCase {
  LogoutUseCase(this._session);

  final UserSessionService _session;

  Future<void> call() => _session.logout();
}
