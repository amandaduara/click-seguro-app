import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/avatar_update_outcome.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/failures/profile_failures.dart';
import 'package:click_seguro_app/modules/profile/domain/validators/profile_form_validator.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/edit_profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../fakes/fake_image_storage_service.dart';
import '../../../../fakes/fake_secure_storage_service.dart';
import '../../fakes/edit_profile_controller_factory.dart';
import '../../fakes/fake_profile_repository.dart';

void main() {
  late FakeProfileRepository repository;
  late UserSessionService session;
  late FakeImageStorageService storage;
  late EditProfileController controller;

  const ProfileEntity withPhone = ProfileEntity(
    name: 'Maria da Silva',
    email: 'maria@exemplo.com',
    phone: '+5511912345678',
  );

  setUp(() async {
    repository = FakeProfileRepository()
      ..profileResults[0] = const Right(withPhone);
    session = UserSessionService(FakeSecureStorageService());
    await session.saveSession(
      accessToken: 'token',
      refreshToken: 'refresh',
      email: 'maria@exemplo.com',
      userName: 'Maria da Silva',
    );
    storage = FakeImageStorageService();
    controller = buildEditProfileController(
      repository,
      session,
      imageStorage: storage,
    );
  });

  tearDown(() => controller.dispose());

  Future<void> loaded() => controller.load();

  group('carga', () {
    test('começa com os valores do perfil, telefone com máscara', () async {
      await loaded();

      expect(controller.status, EditProfileStatus.ready);
      expect(controller.name.text, 'Maria da Silva');
      expect(controller.email.text, 'maria@exemplo.com');
      expect(controller.phone.text, '(11) 91234-5678');
    });

    test('falha → error com a falha', () async {
      repository.profileResults[0] = const Left(ConnectionFailure());

      await loaded();

      expect(controller.status, EditProfileStatus.error);
      expect(controller.failure, isA<ConnectionFailure>());
    });
  });

  group('canSave e hasChanges', () {
    test('sem mudança, falso', () async {
      await loaded();

      expect(controller.hasChanges, isFalse);
      expect(controller.canSave, isFalse);
    });

    test('mudar um campo liga; voltar ao original desliga', () async {
      await loaded();

      controller.name.text = 'Maria Souza';
      expect(controller.canSave, isTrue);

      controller.name.text = ' Maria da Silva ';
      expect(controller.hasChanges, isFalse);
    });

    test('mudar só a máscara do telefone não conta', () async {
      await loaded();

      controller.phone.text = '11912345678';

      expect(controller.hasChanges, isFalse);
    });
  });

  group('validação enquanto digita', () {
    test('ao carregar, nenhum erro', () async {
      await loaded();

      expect(controller.errors.isEmpty, isTrue);
    });

    test('erro aparece só no campo alterado e desativa "Salvar"', () async {
      await loaded();

      controller.name.text = 'Ana';

      expect(controller.errors.name, ProfileFieldError.nameLength);
      expect(controller.errors.email, isNull);
      expect(controller.errors.phone, isNull);
      expect(controller.hasChanges, isTrue);
      expect(controller.canSave, isFalse);
    });

    test('o erro some assim que o campo fica válido', () async {
      await loaded();
      controller.email.text = 'maria@';
      expect(controller.errors.email, ProfileFieldError.emailInvalid);

      controller.email.text = 'maria@novo.com';

      expect(controller.errors.email, isNull);
      expect(controller.canSave, isTrue);
    });

    test('telefone incompleto é inválido; 10 ou 11 dígitos, válido', () async {
      await loaded();

      controller.phone.text = '(11) 9123';
      expect(controller.errors.phone, ProfileFieldError.phoneInvalid);
      expect(controller.canSave, isFalse);

      controller.phone.text = '(11) 3456-7890';
      expect(controller.errors.phone, isNull);
      expect(controller.canSave, isTrue);

      controller.phone.text = '(11) 93456-7890';
      expect(controller.errors.phone, isNull);
    });

    test('apagar o telefone salvo mostra o erro na hora', () async {
      await loaded();

      controller.phone.text = '';

      expect(controller.errors.phone, ProfileFieldError.phoneRequired);
      expect(controller.canSave, isFalse);
    });

    test('avisa a tela a cada letra', () async {
      await loaded();
      var notified = 0;
      controller.addListener(() => notified++);

      controller.name.text = 'A';
      controller.name.text = 'An';

      expect(notified, 2);
    });

    test('campo não alterado e inválido só aparece ao salvar', () async {
      repository.profileResults[0] = const Right(
        ProfileEntity(name: 'Ana', email: 'ana@exemplo.com'),
      );
      await loaded();
      controller.phone.text = '(11) 91234-5678';
      expect(controller.errors.name, isNull);
      expect(controller.canSave, isTrue);

      final result = await controller.save();

      expect(result, EditSaveResult.invalid);
      expect(controller.errors.name, ProfileFieldError.nameLength);
      expect(controller.canSave, isFalse);
      expect(repository.updateCalls, isEmpty);
    });

    test(
      'e-mail em uso fica até mudar o e-mail, com "Salvar" desativado',
      () async {
        repository.updateResults[0] = const Left(EmailInUseFailure());
        await loaded();
        controller.email.text = 'ja@exemplo.com';
        await controller.save();

        controller.name.text = 'Maria Souza';
        expect(controller.errors.email, ProfileFieldError.emailInUse);
        expect(controller.canSave, isFalse);

        controller.email.text = 'outro@exemplo.com';
        expect(controller.errors.email, isNull);
        expect(controller.canSave, isTrue);
      },
    );

    test('salvo com sucesso, nenhum campo conta como alterado', () async {
      await loaded();
      controller.name.text = 'Maria Souza';
      await controller.save();

      expect(controller.errors.isEmpty, isTrue);
      controller.email.text = 'maria@';
      expect(controller.errors.name, isNull);
      expect(controller.errors.email, ProfileFieldError.emailInvalid);
    });
  });

  group('save', () {
    test('erros por campo sem chamar o serviço', () async {
      await loaded();
      controller
        ..name.text = 'Ana'
        ..email.text = 'maria@'
        ..phone.text = '';

      final result = await controller.save();

      expect(result, EditSaveResult.invalid);
      expect(controller.errors.name, ProfileFieldError.nameLength);
      expect(controller.errors.email, ProfileFieldError.emailInvalid);
      expect(controller.errors.phone, ProfileFieldError.phoneRequired);
      expect(repository.updateCalls, isEmpty);
    });

    test('editar um campo com erro limpa o erro dele', () async {
      await loaded();
      controller.name.text = 'Ana';
      await controller.save();

      controller.name.text = 'Ana Maria';

      expect(controller.errors.name, isNull);
    });

    test('EmailInUseFailure → erro no e-mail e rascunho mantido', () async {
      repository.updateResults[0] = const Left(EmailInUseFailure());
      await loaded();
      controller.email.text = 'ja@exemplo.com';

      final result = await controller.save();

      expect(result, EditSaveResult.invalid);
      expect(controller.errors.email, ProfileFieldError.emailInUse);
      expect(controller.email.text, 'ja@exemplo.com');
    });

    test('ServerFailure → failed, falha guardada e rascunho mantido', () async {
      repository.updateResults[0] = const Left(ServerFailure());
      await loaded();
      controller.name.text = 'Maria Souza';

      final result = await controller.save();

      expect(result, EditSaveResult.failed);
      expect(controller.saveFailure, isA<ServerFailure>());
      expect(controller.name.text, 'Maria Souza');
      expect(controller.canSave, isTrue);
    });

    test('isSaving durante o envio', () async {
      repository.updateGate = Completer<void>();
      await loaded();
      controller.name.text = 'Maria Souza';

      final saving = controller.save();
      expect(controller.isSaving, isTrue);
      expect(controller.canSave, isFalse);

      repository.updateGate!.complete();
      await saving;
      expect(controller.isSaving, isFalse);
    });

    test('sucesso → canSave falso e originais atualizados', () async {
      await loaded();
      controller.name.text = 'Maria Souza';

      final result = await controller.save();

      expect(result, EditSaveResult.saved);
      expect(controller.canSave, isFalse);
      expect(controller.hasChanges, isFalse);
      expect(session.userName, 'Maria Souza');
    });
  });

  group('foto', () {
    const String localPath = '/app/images/img_1.png';
    const String oldUrl = 'https://img.test/antiga.png';

    setUp(() {
      repository.profileResults[0] = const Right(
        ProfileEntity(
          name: 'Maria da Silva',
          email: 'maria@exemplo.com',
          avatarUrl: oldUrl,
        ),
      );
      storage.nextResult = const PickedImage(localPath);
    });

    test('pickPhoto: foto local enquanto envia, depois a nova URL', () async {
      repository.uploadGate = Completer<void>();
      await loaded();

      final picking = controller.pickPhoto(PhotoSource.gallery);
      await Future<void>.delayed(Duration.zero);

      expect(controller.photoState, PhotoState.uploading);
      expect(controller.localPhotoPath, localPath);

      repository.uploadGate!.complete();
      final outcome = await picking;

      expect(outcome, isA<AvatarUpdated>());
      expect(controller.photoState, PhotoState.idle);
      expect(controller.localPhotoPath, isNull);
      expect(controller.avatarUrl, 'https://img.test/nova.png');
    });

    test('falha no envio volta à foto anterior e devolve a falha', () async {
      repository.uploadResults[0] = const Left(ServerFailure());
      await loaded();

      final outcome = await controller.pickPhoto(PhotoSource.camera);

      expect(outcome, isA<AvatarUpdateFailed>());
      expect(controller.photoState, PhotoState.idle);
      expect(controller.localPhotoPath, isNull);
      expect(controller.avatarUrl, oldUrl);
    });

    test('desistir não muda nada', () async {
      storage.nextResult = const PickImageCancelled();
      await loaded();

      final outcome = await controller.pickPhoto(PhotoSource.gallery);

      expect(outcome, isA<AvatarPickCancelled>());
      expect(controller.avatarUrl, oldUrl);
    });

    test('removePhoto: removing, depois sem foto', () async {
      repository.removeGate = Completer<void>();
      await loaded();

      final removing = controller.removePhoto();
      expect(controller.photoState, PhotoState.removing);
      expect(controller.avatarUrl, isNull);

      repository.removeGate!.complete();
      expect(await removing, isNull);
      expect(controller.photoState, PhotoState.idle);
      expect(controller.avatarUrl, isNull);
    });

    test('falha ao remover → a foto volta', () async {
      repository.removeResults[0] = const Left(ConnectionFailure());
      await loaded();

      final failure = await controller.removePhoto();

      expect(failure, isA<ConnectionFailure>());
      expect(controller.avatarUrl, oldUrl);
    });

    test('o carregamento continua até a imagem nova pré-carregar', () async {
      await loaded();
      final Completer<void> precache = Completer<void>();
      final List<String> prepared = [];

      final picking = controller.pickPhoto(
        PhotoSource.gallery,
        prepareImage: (url) {
          prepared.add(url);
          return precache.future;
        },
      );
      await pumpEventQueue();

      expect(prepared, ['https://img.test/nova.png']);
      expect(controller.photoState, PhotoState.uploading);
      expect(controller.localPhotoPath, localPath);

      precache.complete();
      await picking;
      expect(controller.photoState, PhotoState.idle);
      expect(controller.avatarUrl, 'https://img.test/nova.png');
    });

    test('depois do envio, busca o perfil ainda com o carregamento', () async {
      await loaded();
      repository
        ..profileResults[0] = const Right(
          ProfileEntity(
            name: 'Maria da Silva',
            email: 'maria@exemplo.com',
            avatarUrl: 'https://img.test/nova.png',
          ),
        )
        ..profileGate = Completer<void>();

      final picking = controller.pickPhoto(PhotoSource.gallery);
      await pumpEventQueue();

      expect(repository.uploadCalls, [localPath]);
      expect(repository.profileCalls, 2);
      expect(controller.photoState, PhotoState.uploading);

      repository.profileGate!.complete();
      await picking;
      expect(controller.photoState, PhotoState.idle);
      // O Perfil lê este perfil ao voltar, sem esperar nova busca.
      expect(repository.lastProfile!.avatarUrl, 'https://img.test/nova.png');
    });

    test('a busca traz outro endereço → pré-carrega também', () async {
      await loaded();
      repository.profileResults[0] = const Right(
        ProfileEntity(
          name: 'Maria da Silva',
          email: 'maria@exemplo.com',
          avatarUrl: 'https://img.test/nova.png?v=2',
        ),
      );
      final List<String> prepared = [];

      await controller.pickPhoto(
        PhotoSource.gallery,
        prepareImage: (url) async => prepared.add(url),
      );

      expect(prepared, [
        'https://img.test/nova.png',
        'https://img.test/nova.png?v=2',
      ]);
    });

    test('falha no envio não busca nem pré-carrega', () async {
      repository.uploadResults[0] = const Left(ServerFailure());
      await loaded();
      final List<String> prepared = [];

      await controller.pickPhoto(
        PhotoSource.gallery,
        prepareImage: (url) async => prepared.add(url),
      );

      expect(prepared, isEmpty);
      expect(repository.profileCalls, 1);
    });

    test('removePhoto busca o perfil antes de terminar', () async {
      await loaded();
      repository
        ..profileResults[0] = const Right(testProfile)
        ..profileGate = Completer<void>();

      final removing = controller.removePhoto();
      await pumpEventQueue();

      expect(repository.removeCalls, 1);
      expect(repository.profileCalls, 2);
      expect(controller.photoState, PhotoState.removing);

      repository.profileGate!.complete();
      expect(await removing, isNull);
      expect(controller.photoState, PhotoState.idle);
      expect(repository.lastProfile!.avatarUrl, isNull);
    });

    test('falha ao remover não busca o perfil', () async {
      repository.removeResults[0] = const Left(ConnectionFailure());
      await loaded();

      await controller.removePhoto();

      expect(repository.profileCalls, 1);
    });

    test('trocar a foto não conta como alteração dos campos', () async {
      await loaded();

      await controller.pickPhoto(PhotoSource.gallery);

      expect(controller.hasChanges, isFalse);
    });
  });
}
