import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/change_password_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_account_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_app_version_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_language_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/logout_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/save_language_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/set_receive_alerts_usecase.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/change_password_controller.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/settings_controller.dart';
import 'package:get_it/get_it.dart';

import '../fakes/fake_app_info_service.dart';
import '../modules/settings/fakes/fake_account_repository.dart';
import '../modules/settings/fakes/fake_language_repository.dart';

/// O que as rotas das Configurações buscam no `GetIt` (usecases e
/// controllers), sobre fakes. A `UserSessionService` já precisa estar
/// registrada. Devolve o repository da conta usado.
FakeAccountRepository registerSettingsDependencies(
  GetIt injector, {
  FakeAccountRepository? accountRepository,
  FakeAppInfoService? appInfo,
  FakeLanguageRepository? languages,
}) {
  final FakeLanguageRepository language = languages ?? FakeLanguageRepository();
  final FakeAccountRepository account =
      accountRepository ?? FakeAccountRepository();
  injector
    ..registerSingleton(GetAccountUseCase(account))
    ..registerSingleton(GetAppVersionUseCase(appInfo ?? FakeAppInfoService()))
    ..registerLazySingleton(() => LogoutUseCase(injector<UserSessionService>()))
    ..registerSingleton(ChangePasswordUseCase(account))
    ..registerSingleton(SetReceiveAlertsUseCase(account))
    ..registerSingleton(GetLanguageUseCase(language))
    ..registerSingleton(SaveLanguageUseCase(language))
    ..registerFactory(
      () => ChangePasswordController(
        changePassword: injector<ChangePasswordUseCase>(),
        logout: injector<LogoutUseCase>(),
      ),
    )
    ..registerFactory(
      () => SettingsController(
        getAccount: injector<GetAccountUseCase>(),
        getAppVersion: injector<GetAppVersionUseCase>(),
        logout: injector<LogoutUseCase>(),
        setReceiveAlerts: injector<SetReceiveAlertsUseCase>(),
        getLanguage: injector<GetLanguageUseCase>(),
        saveLanguage: injector<SaveLanguageUseCase>(),
      ),
    );
  return account;
}
