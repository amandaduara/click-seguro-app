import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';

/// 401 `INVALID_CREDENTIALS` na troca de senha: só o aviso no campo, a
/// sessão continua (CB-013).
class WrongCurrentPasswordFailure extends Failure {
  const WrongCurrentPasswordFailure()
    : super(AppStrings.settingsPasswordErrorCurrent);
}

/// 409 `USER_NEW_PASSWORD_EQUALS_OLD`.
class SamePasswordFailure extends Failure {
  const SamePasswordFailure() : super(AppStrings.settingsPasswordErrorSame);
}

/// Nova senha fora do RN-001 chegando ao usecase. Proteção: o controller
/// valida antes, então a tela nunca a mostra.
class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure() : super(AppStrings.settingsPasswordErrorRules);
}

/// A senha foi trocada, mas entrar de novo com ela falhou (R0 de
/// specs/013): a sessão é encerrada e a pessoa entra pelo login.
class PasswordChangedReloginFailure extends Failure {
  const PasswordChangedReloginFailure()
    : super(AppStrings.settingsPasswordRelogin);
}
