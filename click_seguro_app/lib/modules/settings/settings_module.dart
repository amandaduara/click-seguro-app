import 'dart:async';

import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/common/services/app_info_service.dart';
import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/settings/data/datasources/account_remote_data_source.dart';
import 'package:click_seguro_app/modules/settings/data/datasources/account_remote_data_source_impl.dart';
import 'package:click_seguro_app/modules/settings/data/datasources/accessibility_local_data_source.dart';
import 'package:click_seguro_app/modules/settings/data/datasources/accessibility_local_data_source_impl.dart';
import 'package:click_seguro_app/modules/settings/data/datasources/language_local_data_source.dart';
import 'package:click_seguro_app/modules/settings/data/datasources/language_local_data_source_impl.dart';
import 'package:click_seguro_app/modules/settings/data/repositories/account_repository_impl.dart';
import 'package:click_seguro_app/modules/settings/data/repositories/accessibility_repository_impl.dart';
import 'package:click_seguro_app/modules/settings/data/repositories/language_repository_impl.dart';
import 'package:click_seguro_app/modules/settings/domain/repositories/accessibility_repository.dart';
import 'package:click_seguro_app/modules/settings/domain/repositories/account_repository.dart';
import 'package:click_seguro_app/modules/settings/domain/repositories/language_repository.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/change_password_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_accessibility_preferences_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_account_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_app_version_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_language_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/logout_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/save_language_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/set_receive_alerts_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/save_accessibility_preferences_usecase.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/accessibility_controller.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/change_password_controller.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/settings_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class SettingsModule implements ModuleInterface {
  @override
  FutureOr<void> registerServices(GetIt injector) {
    injector
      ..registerLazySingleton<AccountRemoteDataSource>(
        () => AccountRemoteDataSourceImpl(injector<ApiClient>()),
      )
      ..registerLazySingleton<AccountRepository>(
        () => AccountRepositoryImpl(
          injector<AccountRemoteDataSource>(),
          injector<UserSessionService>(),
        ),
      )
      ..registerLazySingleton<LanguageLocalDataSource>(
        () => LanguageLocalDataSourceImpl(injector<LocalCacheService>()),
      )
      ..registerLazySingleton<LanguageRepository>(
        () => LanguageRepositoryImpl(injector<LanguageLocalDataSource>()),
      )
      ..registerLazySingleton(
        () => GetAccountUseCase(injector<AccountRepository>()),
      )
      ..registerLazySingleton(
        () => GetAppVersionUseCase(injector<AppInfoService>()),
      )
      ..registerLazySingleton(
        () => LogoutUseCase(injector<UserSessionService>()),
      )
      ..registerLazySingleton(
        () => ChangePasswordUseCase(injector<AccountRepository>()),
      )
      ..registerLazySingleton(
        () => SetReceiveAlertsUseCase(injector<AccountRepository>()),
      )
      ..registerLazySingleton(
        () => GetLanguageUseCase(injector<LanguageRepository>()),
      )
      ..registerLazySingleton(
        () => SaveLanguageUseCase(injector<LanguageRepository>()),
      )
      ..registerFactory(
        () => ChangePasswordController(
          changePassword: injector<ChangePasswordUseCase>(),
          logout: injector<LogoutUseCase>(),
        ),
      )
      // Um por abertura da tela.
      ..registerFactory(
        () => SettingsController(
          getAccount: injector<GetAccountUseCase>(),
          getAppVersion: injector<GetAppVersionUseCase>(),
          logout: injector<LogoutUseCase>(),
          setReceiveAlerts: injector<SetReceiveAlertsUseCase>(),
          getLanguage: injector<GetLanguageUseCase>(),
          saveLanguage: injector<SaveLanguageUseCase>(),
        ),
      )
      ..registerLazySingleton<AccessibilityLocalDataSource>(
        () => AccessibilityLocalDataSourceImpl(injector<LocalCacheService>()),
      )
      ..registerLazySingleton<AccessibilityRepository>(
        () => AccessibilityRepositoryImpl(
          injector<AccessibilityLocalDataSource>(),
        ),
      )
      ..registerLazySingleton(
        () => GetAccessibilityPreferencesUseCase(
          injector<AccessibilityRepository>(),
        ),
      )
      ..registerLazySingleton(
        () => SaveAccessibilityPreferencesUseCase(
          injector<AccessibilityRepository>(),
        ),
      )
      // Um só: carregado no setupApp() e usado pela tela da B9.
      ..registerLazySingleton(
        () => AccessibilityController(
          getPreferences: injector<GetAccessibilityPreferencesUseCase>(),
          savePreferences: injector<SaveAccessibilityPreferencesUseCase>(),
          notifier: injector<AccessibilityPreferencesNotifier>(),
        ),
      );
  }

  @override
  List<SingleChildWidget> providers(GetIt injector) => [
    ChangeNotifierProvider.value(value: injector<AccessibilityController>()),
  ];
}
