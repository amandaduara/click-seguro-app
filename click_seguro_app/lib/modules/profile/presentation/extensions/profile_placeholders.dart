import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';

/// Dados de exemplo para o esqueleto do perfil (specs/022 R8).
abstract final class ProfilePlaceholders {
  static ProfileEntity profile() =>
      ProfileEntity(name: SafeSkeleton.text(2), email: SafeSkeleton.text(1));
}
