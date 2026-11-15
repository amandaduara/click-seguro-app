import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/repositories/profile_repository.dart';

/// O último perfil já buscado (ou `null`), sem novo pedido: a tela mostra na
/// hora o que outra tela acabou de atualizar (R20.5 de specs/024).
class GetCachedProfileUseCase {
  GetCachedProfileUseCase(this._repository);

  final ProfileRepository _repository;

  ProfileEntity? call() => _repository.lastProfile;
}
