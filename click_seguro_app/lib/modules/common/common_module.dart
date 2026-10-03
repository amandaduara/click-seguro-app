import 'dart:async';

import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/common/services/local_cache_service.dart';
import 'package:click_seguro_app/modules/common/services/secure_storage_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommonModule implements ModuleInterface {
  @override
  List<SingleChildWidget> providers(GetIt injector) {
    return [];
  }

  @override
  Future<void> registerServices(GetIt injector) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    injector.registerLazySingleton<SecureStorageService>(
      () => FlutterSecureStorageService(),
    );
    injector.registerLazySingleton<LocalCacheService>(
      () => SharedPreferencesLocalCacheService(preferences),
    );
    injector.registerLazySingleton(
      () => UserSessionService(injector<SecureStorageService>()),
    );
    injector.registerLazySingleton(() => ApiClient());
  }
}
