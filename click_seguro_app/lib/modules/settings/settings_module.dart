import 'dart:async';

import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';
import 'package:click_seguro_app/modules/settings/data/datasources/accessibility_local_data_source.dart';
import 'package:click_seguro_app/modules/settings/data/datasources/accessibility_local_data_source_impl.dart';
import 'package:click_seguro_app/modules/settings/data/repositories/accessibility_repository_impl.dart';
import 'package:click_seguro_app/modules/settings/domain/repositories/accessibility_repository.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/get_accessibility_preferences_usecase.dart';
import 'package:click_seguro_app/modules/settings/domain/usecases/save_accessibility_preferences_usecase.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/accessibility_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class SettingsModule implements ModuleInterface {
  @override
  FutureOr<void> registerServices(GetIt injector) {
    injector
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
