import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';

/// Escolha de foto sem galeria nem câmera, para testes.
class FakeImageStorageService implements ImageStorageService {
  FakeImageStorageService({this.nextResults = const []});

  /// Resultado da próxima [pickImage].
  PickImageResult nextResult = const PickImageCancelled();
  final List<PickImageResult> nextResults;

  final List<PhotoSource> pickedSources = [];
  final List<String> deletedPaths = [];

  @override
  Future<PickImageResult> pickImage(PhotoSource source) async {
    pickedSources.add(source);
    return nextResults.isEmpty ? nextResult : nextResults.removeAt(0);
  }

  @override
  Future<void> delete(String path) async => deletedPaths.add(path);
}
