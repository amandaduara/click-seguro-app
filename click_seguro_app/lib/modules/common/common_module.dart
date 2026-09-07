import 'dart:async';

import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/single_child_widget.dart';

class CommonModule implements ModuleInterface {
  @override
  List<SingleChildWidget> providers(GetIt injector) {
    return [];
  }

  @override
  FutureOr<void> registerServices(GetIt injector) {
    injector.registerLazySingleton(() => UserSessionService());
    injector.registerLazySingleton(() => ApiClient());
  }
}
