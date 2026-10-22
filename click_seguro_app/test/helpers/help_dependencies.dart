import 'package:click_seguro_app/modules/common/services/external_launcher_service.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/help/domain/repositories/help_repository.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/delete_personal_contact_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_official_contacts_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_personal_contacts_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/save_personal_contact_usecase.dart';
import 'package:click_seguro_app/modules/help/presentation/controller/contact_form_controller.dart';
import 'package:click_seguro_app/modules/help/presentation/controller/help_controller.dart';
import 'package:get_it/get_it.dart';

import '../modules/help/fakes/fake_help_repository.dart';
import '../modules/help/fakes/help_fakes.dart';

FakeHelpRepository registerHelpDependencies(
  GetIt injector, {
  FakeHelpRepository? repository,
  FakeImageStorageService? images,
  FakeExternalLauncherService? launcher,
}) {
  final fakeRepository = repository ?? FakeHelpRepository();
  final imageStorage = images ?? FakeImageStorageService();
  final externalLauncher = launcher ?? FakeExternalLauncherService();
  injector
    ..registerSingleton<HelpRepository>(fakeRepository)
    ..registerSingleton<ImageStorageService>(imageStorage)
    ..registerSingleton<ExternalLauncherService>(externalLauncher)
    ..registerLazySingleton(
      () => GetOfficialContactsUseCase(injector<HelpRepository>()),
    )
    ..registerLazySingleton(
      () => GetPersonalContactsUseCase(injector<HelpRepository>()),
    )
    ..registerLazySingleton(
      () => SavePersonalContactUseCase(injector<HelpRepository>()),
    )
    ..registerLazySingleton(
      () => DeletePersonalContactUseCase(injector<HelpRepository>()),
    )
    ..registerFactory(
      () => HelpController(
        getOfficialContacts: injector<GetOfficialContactsUseCase>(),
        getPersonalContacts: injector<GetPersonalContactsUseCase>(),
        launcher: injector<ExternalLauncherService>(),
      ),
    )
    ..registerFactoryParam<ContactFormController, String?, void>(
      (contactId, _) => ContactFormController(
        contactId: contactId,
        getPersonalContacts: injector<GetPersonalContactsUseCase>(),
        savePersonalContact: injector<SavePersonalContactUseCase>(),
        deletePersonalContact: injector<DeletePersonalContactUseCase>(),
        images: injector<ImageStorageService>(),
      ),
    );
  return fakeRepository;
}
