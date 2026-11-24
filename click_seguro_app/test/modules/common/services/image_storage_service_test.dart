import 'dart:io';

import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

/// Escolha de imagem falsa: devolve [result], ou lança [error].
class _FakeImagePicker extends Fake implements ImagePicker {
  XFile? result;
  Object? error;

  ImageSource? source;
  double? maxWidth;
  double? maxHeight;
  int? imageQuality;
  bool? requestFullMetadata;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    this.source = source;
    this.maxWidth = maxWidth;
    this.maxHeight = maxHeight;
    this.imageQuality = imageQuality;
    this.requestFullMetadata = requestFullMetadata;
    final Object? failure = error;
    if (failure != null) throw failure;
    return result;
  }
}

void main() {
  final String sep = Platform.pathSeparator;

  late Directory temp;
  late Directory appDirectory;
  late _FakeImagePicker picker;
  late PlatformImageStorageService service;

  /// Foto "na galeria", fora da pasta do app.
  File createSource(String name, [List<int> bytes = const [1, 2, 3]]) =>
      File('${temp.path}$sep$name')..writeAsBytesSync(bytes);

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('image_storage_test');
    appDirectory = await Directory('${temp.path}${sep}app').create();
    picker = _FakeImagePicker();
    service = PlatformImageStorageService(
      picker: picker,
      appDirectory: () async => appDirectory,
    );
  });

  tearDown(() => temp.delete(recursive: true));

  test('galeria e câmera pedem a foto já reduzida para avatar', () async {
    await service.pickImage(PhotoSource.gallery);
    expect(picker.source, ImageSource.gallery);

    await service.pickImage(PhotoSource.camera);
    expect(picker.source, ImageSource.camera);
    expect(picker.maxWidth, 1024);
    expect(picker.maxHeight, 1024);
    expect(picker.imageQuality, 85);
    expect(picker.requestFullMetadata, isFalse);
  });

  test('guarda uma cópia na pasta do app e devolve o caminho dela', () async {
    final File source = createSource('foto.png', [7, 8, 9]);
    picker.result = XFile(source.path);

    final PickImageResult result = await service.pickImage(PhotoSource.gallery);

    final String path = (result as PickedImage).path;
    expect(path, startsWith('${appDirectory.path}${sep}images$sep'));
    expect(path.split(sep).last, startsWith('img_'));
    expect(path, endsWith('.png'));
    expect(File(path).readAsBytesSync(), [7, 8, 9]);

    // A cópia continua mesmo que a original seja apagada.
    source.deleteSync();
    expect(File(path).existsSync(), isTrue);
  });

  test('origem sem extensão vira .jpg', () async {
    picker.result = XFile(createSource('foto').path);

    final PickImageResult result = await service.pickImage(PhotoSource.camera);

    expect((result as PickedImage).path, endsWith('.jpg'));
  });

  test('duas escolhas do mesmo arquivo geram cópias diferentes', () async {
    picker.result = XFile(createSource('foto.jpg').path);

    final String first =
        ((await service.pickImage(PhotoSource.gallery)) as PickedImage).path;
    final String second =
        ((await service.pickImage(PhotoSource.gallery)) as PickedImage).path;

    expect(first, isNot(second));
    expect(File(first).existsSync(), isTrue);
    expect(File(second).existsSync(), isTrue);
  });

  test('desistir → nenhuma foto', () async {
    picker.result = null;

    expect(
      await service.pickImage(PhotoSource.gallery),
      isA<PickImageCancelled>(),
    );
  });

  test('acesso negado à galeria ou à câmera → sem permissão', () async {
    picker.error = PlatformException(code: 'photo_access_denied');
    expect(
      await service.pickImage(PhotoSource.gallery),
      isA<PickImagePermissionDenied>(),
    );

    picker.error = PlatformException(code: 'camera_access_denied');
    expect(
      await service.pickImage(PhotoSource.camera),
      isA<PickImagePermissionDenied>(),
    );
  });

  test('outras falhas → falhou', () async {
    picker.error = PlatformException(code: 'already_active');
    expect(
      await service.pickImage(PhotoSource.gallery),
      isA<PickImageFailed>(),
    );

    picker.error = Exception('falha simulada');
    expect(
      await service.pickImage(PhotoSource.gallery),
      isA<PickImageFailed>(),
    );
  });

  test('origem que não pode ser copiada → falhou', () async {
    picker.result = XFile('${temp.path}${sep}nao_existe.jpg');

    expect(
      await service.pickImage(PhotoSource.gallery),
      isA<PickImageFailed>(),
    );
  });

  group('delete', () {
    test('apaga a cópia; apagar de novo não é erro', () async {
      picker.result = XFile(createSource('foto.jpg').path);
      final String path =
          ((await service.pickImage(PhotoSource.gallery)) as PickedImage).path;

      await service.delete(path);
      expect(File(path).existsSync(), isFalse);

      await expectLater(service.delete(path), completes);
    });

    test('não apaga arquivos fora da pasta de fotos do app', () async {
      final File outside = createSource('outro.jpg');
      final File inAppRoot = File('${appDirectory.path}${sep}dados.json')
        ..writeAsStringSync('{}');

      await service.delete(outside.path);
      await service.delete(inAppRoot.path);
      await service.delete(
        '${appDirectory.path}${sep}images$sep..${sep}dados.json',
      );

      expect(outside.existsSync(), isTrue);
      expect(inAppRoot.existsSync(), isTrue);
    });
  });
}
