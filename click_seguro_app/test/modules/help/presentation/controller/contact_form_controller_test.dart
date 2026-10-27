import 'dart:async';

import 'package:click_seguro_app/core/errors/cache_failure.dart';
import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:fpdart/fpdart.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/delete_personal_contact_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_personal_contacts_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/save_personal_contact_usecase.dart';
import 'package:click_seguro_app/modules/help/presentation/controller/contact_form_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_help_repository.dart';
import '../../../../fakes/fake_image_storage_service.dart';

void main() {
  test('salva campos normalizados e mantém id estável na edição', () async {
    final repository = FakeHelpRepository()..personal = [person];
    final controller = _controller(repository, contactId: 'p1');
    await controller.load();
    controller.setName(' Ana atualizada ');
    controller.setPhone('(11) 98888-7777');

    expect(await controller.save(), isTrue);
    expect(repository.saved?.id, 'p1');
    expect(repository.saved?.name, 'Ana atualizada');
    expect(repository.saved?.phone, '11988887777');
    controller.dispose();
  });

  test(
    'falha ao carregar edição bloqueia novo contato e pode ser repetida',
    () async {
      final repository = FakeHelpRepository()
        ..readFailure = const CacheFailure();
      final controller = _controller(repository, contactId: 'p1');
      await controller.load();
      expect(controller.loadFailure, isA<CacheFailure>());
      expect(await controller.save(), isFalse);

      repository
        ..readFailure = null
        ..personal = [person];
      await controller.load();
      expect(controller.loadFailure, isNull);
      expect(controller.notFound, isFalse);
      expect(controller.name, 'Ana');
      controller.dispose();
    },
  );

  test(
    'validação local impede persistência e falha de cache fica exposta',
    () async {
      final repository = FakeHelpRepository()
        ..writeFailure = const CacheFailure();
      final controller = _controller(repository);
      controller.setName(' ');
      expect(await controller.save(), isFalse);
      expect(controller.validationError, isNotNull);
      controller.setName('Ana');
      controller.setPhone('11ABC');
      expect(await controller.save(), isFalse);
      expect(controller.validationError, isNotNull);
      controller.setPhone('11999999999');
      expect(await controller.save(), isFalse);
      expect(controller.saveFailure, isA<CacheFailure>());
      controller.dispose();
    },
  );

  test(
    'trocar foto temporária apaga a anterior; cancelar apaga atual',
    () async {
      final images = FakeImageStorageService(
        nextResults: [
          const PickedImage('/temp/one.jpg'),
          const PickedImage('/temp/two.jpg'),
        ],
      );
      final controller = _controller(FakeHelpRepository(), images: images);
      await controller.pickPhoto(PhotoSource.gallery);
      await controller.pickPhoto(PhotoSource.camera);

      expect(images.deletedPaths, ['/temp/one.jpg']);
      controller.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(images.deletedPaths, ['/temp/one.jpg', '/temp/two.jpg']);
    },
  );

  test(
    'dispose durante save não apaga foto se a persistência conclui',
    () async {
      final repository = FakeHelpRepository();
      final images = FakeImageStorageService(
        nextResults: [const PickedImage('/temp/saved.jpg')],
      );
      final controller = _controller(repository, images: images);
      controller
        ..setName('Ana')
        ..setPhone('11999999999');
      await controller.pickPhoto(PhotoSource.gallery);
      final completer = Completer<Either<Failure, ContactEntity>>();
      repository.saveCompleter = completer;

      final saving = controller.save();
      await Future<void>.delayed(Duration.zero);
      controller.dispose();
      completer.complete(
        const Right(
          ContactEntity(
            id: 'contact',
            name: 'Ana',
            phone: '11999999999',
            type: ContactType.personal,
            photoPath: '/temp/saved.jpg',
          ),
        ),
      );

      expect(await saving, isTrue);
      expect(images.deletedPaths, isEmpty);
    },
  );

  test('permissão negada não bloqueia salvamento sem foto', () async {
    final images = FakeImageStorageService()
      ..nextResult = const PickImagePermissionDenied();
    final controller = _controller(FakeHelpRepository(), images: images);
    controller
      ..setName('Ana')
      ..setPhone('11999999999');
    await controller.pickPhoto(PhotoSource.gallery);

    expect(controller.permissionDenied, isTrue);
    expect(await controller.save(), isTrue);
    expect(controller.photoPath, isNull);
    controller.dispose();
  });
}

const person = ContactEntity(
  id: 'p1',
  name: 'Ana',
  phone: '11999999999',
  type: ContactType.personal,
);

ContactFormController _controller(
  FakeHelpRepository repository, {
  String? contactId,
  FakeImageStorageService? images,
}) => ContactFormController(
  contactId: contactId,
  getPersonalContacts: GetPersonalContactsUseCase(repository),
  savePersonalContact: SavePersonalContactUseCase(repository),
  deletePersonalContact: DeletePersonalContactUseCase(repository),
  images: images ?? FakeImageStorageService(),
);
