import 'package:click_seguro_app/core/errors/failure.dart';

/// Resultado de trocar a foto (US3 de specs/012-perfil).
sealed class AvatarUpdateOutcome {
  const AvatarUpdateOutcome();
}

final class AvatarUpdated extends AvatarUpdateOutcome {
  const AvatarUpdated(this.avatarUrl);

  final String avatarUrl;
}

/// A pessoa desistiu da galeria ou da câmera: nada muda.
final class AvatarPickCancelled extends AvatarUpdateOutcome {
  const AvatarPickCancelled();
}

/// Acesso às fotos ou à câmera negado (CB-010).
final class AvatarPermissionDenied extends AvatarUpdateOutcome {
  const AvatarPermissionDenied();
}

final class AvatarUpdateFailed extends AvatarUpdateOutcome {
  const AvatarUpdateFailed(this.failure);

  final Failure failure;
}
