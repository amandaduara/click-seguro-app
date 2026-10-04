import 'dart:async';

import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/common/services/session_validation_service.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/onboarding/onboarding.dart';
import 'package:click_seguro_app/modules/splash/domain/usecases/validate_stored_session_usecase.dart';
import 'package:click_seguro_app/modules/splash/presentation/controller/splash_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class SplashModule implements ModuleInterface {
  @override
  FutureOr<void> registerServices(GetIt injector) {
    injector.registerLazySingleton(
      () => ValidateStoredSessionUseCase(
        injector<SessionValidationService>(),
        injector<UserSessionService>(),
      ),
    );
  }

  @override
  List<SingleChildWidget> providers(GetIt injector) {
    return [
      ChangeNotifierProvider(
        create: (_) => SplashController(
          injector<CheckOnboardingSeenUseCase>(),
          injector<ValidateStoredSessionUseCase>(),
        ),
      ),
    ];
  }
}
