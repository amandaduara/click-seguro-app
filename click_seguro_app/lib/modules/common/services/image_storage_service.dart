import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// De onde vem a foto.
enum PhotoSource { gallery, camera }

/// Resultado de escolher uma foto (FR-013, FR-015).
sealed class PickImageResult {
  const PickImageResult();
}

/// Cópia guardada na pasta do app; [path] é absoluto.
final class PickedImage extends PickImageResult {
  const PickedImage(this.path);

  final String path;
}

/// A pessoa desistiu.
final class PickImageCancelled extends PickImageResult {
  const PickImageCancelled();
}

/// Acesso à galeria ou à câmera negado (CB-010).
final class PickImagePermissionDenied extends PickImageResult {
  const PickImagePermissionDenied();
}

final class PickImageFailed extends PickImageResult {
  const PickImageFailed();
}

/// Foto de contato (B6) ou do perfil (B7), guardada só no aparelho (RN-007).
///
/// Nenhum método lança (FR-017).
abstract class ImageStorageService {
  /// Escolhe ou tira a foto, reduz para no máximo 1024 px no lado maior e
  /// guarda uma cópia com nome único na pasta do app.
  Future<PickImageResult> pickImage(PhotoSource source);

  /// Apaga uma cópia guardada pelo app. Inexistente ou fora da pasta de fotos
  /// do app → ignora.
  Future<void> delete(String path);
}

/// Implementação com `image_picker` e `path_provider` (ver
/// specs/007-servicos-plataforma-voz, research R8).
class PlatformImageStorageService implements ImageStorageService {
  PlatformImageStorageService({
    ImagePicker? picker,
    Future<Directory> Function()? appDirectory,
  }) : _picker = picker ?? ImagePicker(),
       _appDirectory = appDirectory ?? getApplicationDocumentsDirectory;

  static const double _maxSide = 1024;
  static const int _quality = 85;
  static const String _folder = 'images';
  static const String _prefix = 'img_';
  static const String _defaultExtension = '.jpg';
  static const String _parentSegment = '..';

  /// Códigos de permissão negada do `image_picker_android`/`image_picker_ios`.
  static const Set<String> _deniedCodes = {
    'photo_access_denied',
    'camera_access_denied',
  };

  final ImagePicker _picker;
  final Future<Directory> Function() _appDirectory;

  static String get _separator => Platform.pathSeparator;

  @override
  Future<PickImageResult> pickImage(PhotoSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: switch (source) {
          PhotoSource.gallery => ImageSource.gallery,
          PhotoSource.camera => ImageSource.camera,
        },
        maxWidth: _maxSide,
        maxHeight: _maxSide,
        imageQuality: _quality,
        requestFullMetadata: false,
      );
      if (picked == null) return const PickImageCancelled();

      final Directory folder = await (await _imagesFolder()).create(
        recursive: true,
      );
      final String path = _uniquePath(folder, _extensionOf(picked.path));
      await picked.saveTo(path);
      return PickedImage(path);
    } on PlatformException catch (error) {
      return _deniedCodes.contains(error.code)
          ? const PickImagePermissionDenied()
          : const PickImageFailed();
    } catch (_) {
      return const PickImageFailed();
    }
  }

  @override
  Future<void> delete(String path) async {
    try {
      final String folder = (await _imagesFolder()).absolute.path;
      final File file = File(path).absolute;
      final bool insideFolder =
          file.path.startsWith('$folder$_separator') &&
          !file.path.split(_separator).contains(_parentSegment);
      if (insideFolder && await file.exists()) await file.delete();
    } catch (_) {
      // Apagar é best effort: a tela trata arquivo ausente como "sem foto".
    }
  }

  Future<Directory> _imagesFolder() async =>
      Directory('${(await _appDirectory()).path}$_separator$_folder');

  static String _uniquePath(Directory folder, String extension) {
    final String base =
        '${folder.path}$_separator$_prefix${DateTime.now().microsecondsSinceEpoch}';
    String path = '$base$extension';
    for (int copy = 1; File(path).existsSync(); copy++) {
      path = '${base}_$copy$extension';
    }
    return path;
  }

  static String _extensionOf(String path) {
    final String name = path.split(RegExp(r'[/\\]')).last;
    final int dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(dot) : _defaultExtension;
  }
}
