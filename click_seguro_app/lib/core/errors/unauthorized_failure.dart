import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';

/// 401: a sessão expirou. O `ApiClient` já chamou
/// `UserSessionService.expire()` (motivo `expired`); a UI só precisa informar
/// o usuário, sem tirá-lo da tela (FR-012a).
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = AppStrings.errorSessionExpired]);
}
