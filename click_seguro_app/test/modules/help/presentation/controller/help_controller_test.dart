import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_official_contacts_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_personal_contacts_usecase.dart';
import 'package:click_seguro_app/modules/help/presentation/controller/help_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_help_repository.dart';
import '../../../../fakes/fake_external_launcher_service.dart';

void main() {
  test('carrega as listas e expõe falha para repetir', () async {
    final repository = FakeHelpRepository()..official = [official];
    final controller = HelpController(
      getOfficialContacts: GetOfficialContactsUseCase(repository),
      getPersonalContacts: GetPersonalContactsUseCase(repository),
      launcher: FakeExternalLauncherService(),
    );

    await controller.load();

    expect(controller.officialContacts.single.id, official.id);
    expect(controller.isLoading, isFalse);
    controller.dispose();
  });

  test('se chamada não abre discador, informa indisponibilidade', () async {
    final controller = HelpController(
      getOfficialContacts: GetOfficialContactsUseCase(FakeHelpRepository()),
      getPersonalContacts: GetPersonalContactsUseCase(FakeHelpRepository()),
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
      launcher: FakeExternalLauncherService()..openResult = false,
    );

    expect(await controller.call(official), isFalse);
    controller.dispose();
  });
}

const official = ContactEntity(
  id: '190',
  name: 'Polícia',
  phone: '190',
  type: ContactType.official,
);
