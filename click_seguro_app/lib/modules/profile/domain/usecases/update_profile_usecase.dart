import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_update.dart';
import 'package:click_seguro_app/modules/profile/domain/repositories/profile_repository.dart';
import 'package:click_seguro_app/modules/profile/domain/validators/profile_form_validator.dart';
import 'package:fpdart/fpdart.dart';

/// Salva só o que mudou em relação a [original] (FR-013) e, em sucesso,
/// atualiza nome e e-mail da sessão (saudação do Início, SC-003). Os textos
/// já foram validados pelo [ProfileFormValidator].
class UpdateProfileUseCase {
  UpdateProfileUseCase(this._repository, this._session);

  final ProfileRepository _repository;
  final UserSessionService _session;

  /// `Right` com o perfil como ficou; nada mudou → o [original], sem pedido.
  Future<Either<Failure, ProfileEntity>> call({
    required ProfileEntity original,
    required String name,
    required String email,
    required String phone,
  }) async {
    final ProfileUpdate update = _changes(
      original: original,
      name: name,
      email: email,
      phone: phone,
    );
    if (update.isEmpty) return Right(original);

    final result = await _repository.updateProfile(update);
    return result.fold((failure) async => Left(failure), (_) async {
      final ProfileEntity saved = ProfileEntity(
        name: update.name ?? original.name,
        email: update.email ?? original.email,
        phone: update.phone ?? original.phone,
        avatarUrl: original.avatarUrl,
        receiveNotifications: original.receiveNotifications,
      );
      await _session.updateProfile(name: saved.name, email: saved.email);
      return Right(saved);
    });
  }

  /// O que mudou: nome sem espaços nas pontas, e-mail também em minúsculas,
  /// telefone com "+55". Telefone vazio nunca é enviado (o servidor não
  /// apaga, R0).
  static ProfileUpdate _changes({
    required ProfileEntity original,
    required String name,
    required String email,
    required String phone,
  }) {
    final String newName = name.trim();
    final String newEmail = email.trim().toLowerCase();
    final String? newPhone = ProfileFormValidator.normalizePhone(phone);
    return ProfileUpdate(
      name: newName == original.name ? null : newName,
      email: newEmail == original.email.toLowerCase() ? null : newEmail,
      phone: newPhone == null || newPhone == original.phone ? null : newPhone,
    );
  }
}
