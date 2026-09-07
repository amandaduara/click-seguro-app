import 'dart:async';

import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/onboarding/domain/usecases/check_onboarding_seen_usecase.dart';
import 'package:click_seguro_app/modules/splash/presentation/controller/splash_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class SplashModule implements ModuleInterface {
  @override
  FutureOr<void> registerServices(GetIt injector) {}

  @override
  List<SingleChildWidget> providers(GetIt injector) {
    return [
      ChangeNotifierProvider(
        create: (_) => SplashController(injector<CheckOnboardingSeenUseCase>()),
      ),
    ];
  }
}
