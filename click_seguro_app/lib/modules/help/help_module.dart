import 'dart:async';

import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/common/services/external_launcher_service.dart';
import 'package:click_seguro_app/modules/common/services/image_storage_service.dart';
import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';
import 'package:click_seguro_app/modules/help/data/datasources/official_contacts_local_data_source.dart';
import 'package:click_seguro_app/modules/help/data/datasources/personal_contacts_local_data_source.dart';
import 'package:click_seguro_app/modules/help/data/repositories/help_repository_impl.dart';
import 'package:click_seguro_app/modules/help/domain/repositories/help_repository.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/delete_personal_contact_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_official_contacts_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/get_personal_contacts_usecase.dart';
import 'package:click_seguro_app/modules/help/domain/usecases/save_personal_contact_usecase.dart';
import 'package:click_seguro_app/modules/help/presentation/controller/contact_form_controller.dart';
import 'package:click_seguro_app/modules/help/presentation/controller/help_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/single_child_widget.dart';

class HelpModule implements ModuleInterface {
  @override
  FutureOr<void> registerServices(GetIt injector) {
    injector
      ..registerLazySingleton(() => OfficialContactsLocalDataSource())
      ..registerLazySingleton(
        () => PersonalContactsLocalDataSource(
          injector<LocalCacheService>(),
          injector<ImageStorageService>(),
        ),
      )
      ..registerLazySingleton<HelpRepository>(
        () => HelpRepositoryImpl(
          injector<OfficialContactsLocalDataSource>(),
          injector<PersonalContactsLocalDataSource>(),
        ),
      )
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
  }

  @override
  List<SingleChildWidget> providers(GetIt injector) => [];
}
