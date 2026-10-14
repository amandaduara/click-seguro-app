import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/avatar_update_outcome.dart';
import 'package:click_seguro_app/modules/profile/domain/failures/profile_failures.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/remove_avatar_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/update_avatar_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../fakes/fake_image_storage_service.dart';
import '../../fakes/fake_profile_repository.dart';

void main() {
  late FakeProfileRepository repository;
  late FakeImageStorageService storage;
  late UpdateAvatarUseCase updateAvatar;

  const String path = '/app/images/img_1.png';

  setUp(() {
    repository = FakeProfileRepository();
    storage = FakeImageStorageService();
    updateAvatar = UpdateAvatarUseCase(repository, storage);
  });

  group('UpdateAvatarUseCase', () {
    test('foto escolhida: avisa o caminho, envia e apaga a cópia', () async {
      storage.nextResult = const PickedImage(path);
      final List<String> picked = [];

      final outcome = await updateAvatar(
        PhotoSource.camera,
        onPicked: picked.add,
      );

      expect(storage.pickedSources, [PhotoSource.camera]);
      expect(picked, [path]);
      expect(repository.uploadCalls, [path]);
      expect(storage.deletedPaths, [path]);
      expect(outcome, isA<AvatarUpdated>());
      expect((outcome as AvatarUpdated).avatarUrl, 'https://img.test/nova.png');
    });

    test('falha no envio também apaga a cópia', () async {
      storage.nextResult = const PickedImage(path);
      repository.uploadResults[0] = const Left(AvatarTypeFailure());

      final outcome = await updateAvatar(PhotoSource.gallery);

      expect(storage.deletedPaths, [path]);
      expect(outcome, isA<AvatarUpdateFailed>());
      expect((outcome as AvatarUpdateFailed).failure, isA<AvatarTypeFailure>());
    });

    test('desistiu → nada enviado', () async {
      storage.nextResult = const PickImageCancelled();

      final outcome = await updateAvatar(PhotoSource.gallery);

      expect(outcome, isA<AvatarPickCancelled>());
      expect(repository.uploadCalls, isEmpty);
    });

    test('sem permissão → permissionDenied, sem pedido', () async {
      storage.nextResult = const PickImagePermissionDenied();

      final outcome = await updateAvatar(PhotoSource.camera);

      expect(outcome, isA<AvatarPermissionDenied>());
      expect(repository.uploadCalls, isEmpty);
    });

    test('falha ao escolher → falha genérica', () async {
      storage.nextResult = const PickImageFailed();

      final outcome = await updateAvatar(PhotoSource.gallery);

      expect(outcome, isA<AvatarUpdateFailed>());
      expect((outcome as AvatarUpdateFailed).failure, isA<ServerFailure>());
      expect(repository.uploadCalls, isEmpty);
    });
  });

  group('RemoveAvatarUseCase', () {
    test('repassa o sucesso', () async {
      final result = await RemoveAvatarUseCase(repository)();

      expect(result.isRight(), isTrue);
      expect(repository.removeCalls, 1);
    });

    test('repassa a falha', () async {
      repository.removeResults[0] = const Left(ConnectionFailure());

      final result = await RemoveAvatarUseCase(repository)();

      expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
    });
  });
}
