import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/repositories/profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetProfileUseCase {
  GetProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<Failure, ProfileEntity>> call() => _repository.getProfile();

  /// O último perfil já buscado (ou `null`), sem novo pedido: a tela mostra
  /// na hora o que outra tela acabou de atualizar.
  ProfileEntity? get latest => _repository.lastProfile;
}
