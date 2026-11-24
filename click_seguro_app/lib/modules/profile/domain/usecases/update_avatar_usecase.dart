import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/avatar_update_outcome.dart';
import 'package:click_seguro_app/modules/profile/domain/repositories/profile_repository.dart';

/// Escolhe a foto pelo `ImageStorageService` (já reduzida e copiada para a
/// pasta do app), envia e apaga a cópia local, com sucesso ou não (R7).
class UpdateAvatarUseCase {
  UpdateAvatarUseCase(this._repository, this._imageStorage);

  final ProfileRepository _repository;
  final ImageStorageService _imageStorage;

  /// [onPicked] recebe o caminho da cópia antes do envio, para a tela
  /// mostrar a foto nova na hora.
  Future<AvatarUpdateOutcome> call(
    PhotoSource source, {
    void Function(String localPath)? onPicked,
  }) async {
    final PickImageResult picked = await _imageStorage.pickImage(source);
    switch (picked) {
      case PickImageCancelled():
        return const AvatarPickCancelled();
      case PickImagePermissionDenied():
        return const AvatarPermissionDenied();
      case PickImageFailed():
        return const AvatarUpdateFailed(ServerFailure());
      case PickedImage(:final path):
        onPicked?.call(path);
        final result = await _repository.uploadAvatar(path);
        await _imageStorage.delete(path);
        return result.fold(AvatarUpdateFailed.new, AvatarUpdated.new);
    }
  }
}
