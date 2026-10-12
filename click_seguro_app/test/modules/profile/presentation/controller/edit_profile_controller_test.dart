import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/failures/profile_failures.dart';
import 'package:click_seguro_app/modules/profile/domain/validators/profile_form_validator.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/edit_profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../fakes/fake_secure_storage_service.dart';
import '../../fakes/edit_profile_controller_factory.dart';
import '../../fakes/fake_profile_repository.dart';

void main() {
  late FakeProfileRepository repository;
  late UserSessionService session;
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
    controller = buildEditProfileController(repository, session);
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
}
