import 'package:click_seguro_app/modules/common/services/external_launcher_service.dart';
import 'package:click_seguro_app/modules/help/domain/entities/contact_entity.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_official_contacts_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_personal_contacts_usecase.dart';
import 'package:click_seguro_app/modules/help/presentation/controller/help_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_help_repository.dart';

void main() {
  test('carrega as listas e expõe falha para repetir', () async {
    final repository = FakeHelpRepository()..official = [official];
    final controller = HelpController(
      getOfficialContacts: GetOfficialContactsUseCase(repository),
      getPersonalContacts: GetPersonalContactsUseCase(repository),
      launcher: _Launcher(),
    );

    await controller.load();

    expect(controller.officialContacts, [official]);
    expect(controller.isLoading, isFalse);
    controller.dispose();
  });

  test('se chamada não abre discador, expõe número para fallback', () async {
    final controller = HelpController(
      getOfficialContacts: GetOfficialContactsUseCase(FakeHelpRepository()),
      getPersonalContacts: GetPersonalContactsUseCase(FakeHelpRepository()),
      launcher: _Launcher(canCallResult: false),
    );

    final opened = await controller.call(official);

    expect(opened, isFalse);
    expect(controller.fallbackPhone, '190');
    controller.dispose();
  });

  test('se chamada do discador retorna false, usa o mesmo fallback', () async {
    final controller = HelpController(
      getOfficialContacts: GetOfficialContactsUseCase(FakeHelpRepository()),
      getPersonalContacts: GetPersonalContactsUseCase(FakeHelpRepository()),
      launcher: _Launcher(callResult: false),
    );

    expect(await controller.call(official), isFalse);
    expect(controller.fallbackPhone, '190');
    controller.dispose();
  });
}

const official = ContactEntity(
  id: '190',
  name: 'Polícia',
  phone: '190',
  type: ContactType.official,
);

class _Launcher implements ExternalLauncherService {
  _Launcher({this.canCallResult = true, this.callResult = true});
  final bool canCallResult;
  final bool callResult;
  @override
  Future<bool> canCall() async => canCallResult;
  @override
  Future<bool> call(String phoneNumber) async => callResult;
  @override
  Future<bool> openUrl(String url) async => false;
}
