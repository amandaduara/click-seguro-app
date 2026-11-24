import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:click_seguro_app/core/errors/cache_failure.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/delete_personal_contact_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_official_contacts_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_personal_contacts_usecase.dart';
import 'package:click_seguro_app/modules/help/presentation/controller/help_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_help_repository.dart';
import '../../../../fakes/fake_external_launcher_service.dart';

void main() {
  // Remover pelo cartão da lista, com a lixeira ao lado de ligar
  // (validação da usuária, specs/024).
  group('remover contato pessoal', () {
    const ContactEntity ana = ContactEntity(
      id: 'p1',
      name: 'Ana',
      phone: '11912345678',
      type: ContactType.personal,
    );

    HelpController build(FakeHelpRepository repository) => HelpController(
      getOfficialContacts: GetOfficialContactsUseCase(repository),
      getPersonalContacts: GetPersonalContactsUseCase(repository),
      deletePersonalContact: DeletePersonalContactUseCase(repository),
      launcher: FakeExternalLauncherService(),
    );

    test('remove da lista e do repositório', () async {
      final repository = FakeHelpRepository()..personal = [ana];
      final controller = build(repository);
      await controller.load();

      final Future<Object?> deleting = controller.deleteContact('p1');
      expect(controller.isDeleting('p1'), isTrue);
      expect(await deleting, isNull);

      expect(controller.isDeleting('p1'), isFalse);
      expect(controller.personalContacts, isEmpty);
      expect(repository.deletedId, 'p1');
      controller.dispose();
    });

    test('falha: o contato fica e a falha volta', () async {
      final repository = FakeHelpRepository()..personal = [ana];
      final controller = build(repository);
      await controller.load();
      repository.writeFailure = const CacheFailure();

      expect(await controller.deleteContact('p1'), isA<CacheFailure>());

      expect(controller.personalContacts.single.id, 'p1');
      expect(controller.isDeleting('p1'), isFalse);
      controller.dispose();
    });
  });

  test('carrega as listas e expõe falha para repetir', () async {
    final repository = FakeHelpRepository()..official = [official];
    final controller = HelpController(
      getOfficialContacts: GetOfficialContactsUseCase(repository),
      getPersonalContacts: GetPersonalContactsUseCase(repository),
      deletePersonalContact: DeletePersonalContactUseCase(repository),
      launcher: FakeExternalLauncherService(),
    );

    await controller.load();

    expect(controller.officialContacts.single.id, official.id);
    expect(controller.isLoading, isFalse);
    controller.dispose();
  });

  test('oficiais chegam na ordem do repositório, com descrição', () async {
    final repository = FakeHelpRepository()
      ..official = const [
        ContactEntity(
          id: 'pm',
          name: 'Polícia Militar',
          phone: '190',
          type: ContactType.official,
          description: 'Emergência: ligue 190 se estiver em perigo',
        ),
        ContactEntity(
          id: 'anatel',
          name: 'Anatel',
          phone: '1331',
          type: ContactType.official,
          description: 'Reclamações de telefonia: 1331',
        ),
      ];
    final controller = HelpController(
      getOfficialContacts: GetOfficialContactsUseCase(repository),
      getPersonalContacts: GetPersonalContactsUseCase(repository),
      deletePersonalContact: DeletePersonalContactUseCase(repository),
      launcher: FakeExternalLauncherService(),
    );

    await controller.load();

    expect(controller.officialContacts.map((c) => c.id), ['pm', 'anatel']);
    expect(
      controller.officialContacts.first.description,
      'Emergência: ligue 190 se estiver em perigo',
    );
    expect(controller.officialFailure, isNull);
    controller.dispose();
  });

  test('se chamada não abre discador, informa indisponibilidade', () async {
    final controller = HelpController(
      getOfficialContacts: GetOfficialContactsUseCase(FakeHelpRepository()),
      getPersonalContacts: GetPersonalContactsUseCase(FakeHelpRepository()),
      deletePersonalContact: DeletePersonalContactUseCase(FakeHelpRepository()),
      launcher: FakeExternalLauncherService()..canCallResult = false,
    );

    final opened = await controller.call(official);

    expect(opened, isFalse);
    controller.dispose();
  });

  test('se discador não abre, a chamada retorna false', () async {
    final controller = HelpController(
      getOfficialContacts: GetOfficialContactsUseCase(FakeHelpRepository()),
      getPersonalContacts: GetPersonalContactsUseCase(FakeHelpRepository()),
      deletePersonalContact: DeletePersonalContactUseCase(FakeHelpRepository()),
      launcher: FakeExternalLauncherService()..openResult = false,
    );

    expect(await controller.call(official), isFalse);
    controller.dispose();
  });

  callNumberTests();
}

// FR-016 de specs/024-redesign-visual: o cartão "Caiu em um golpe?" liga
// para um número, com a mesma regra dos contatos.
void callNumberTests() {
  test('callNumber liga para o número pedido', () async {
    final launcher = FakeExternalLauncherService();
    final controller = HelpController(
      getOfficialContacts: GetOfficialContactsUseCase(FakeHelpRepository()),
      getPersonalContacts: GetPersonalContactsUseCase(FakeHelpRepository()),
      deletePersonalContact: DeletePersonalContactUseCase(FakeHelpRepository()),
      launcher: launcher,
    );

    expect(await controller.callNumber('190'), isTrue);
    expect(launcher.calledNumbers, ['190']);
    controller.dispose();
  });

  test('callNumber sem discador devolve false e não liga', () async {
    final launcher = FakeExternalLauncherService()..canCallResult = false;
    final controller = HelpController(
      getOfficialContacts: GetOfficialContactsUseCase(FakeHelpRepository()),
      getPersonalContacts: GetPersonalContactsUseCase(FakeHelpRepository()),
      deletePersonalContact: DeletePersonalContactUseCase(FakeHelpRepository()),
      launcher: launcher,
    );

    expect(await controller.callNumber('190'), isFalse);
    expect(launcher.calledNumbers, isEmpty);
    controller.dispose();
  });
}

const official = ContactEntity(
  id: '190',
  name: 'Polícia',
  phone: '190',
  type: ContactType.official,
);
