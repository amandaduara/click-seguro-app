import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/splash/presentation/controller/splash_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../modules/splash/fakes/fake_splash_usecases.dart';

/// Splash sem espera, com onboarding já visto: abre o app real (rota `/`)
/// e segue o destino de [status], como no aparelho.
SingleChildWidget fakeSplashProvider(UserSessionStatus status) =>
    ChangeNotifierProvider(
      create: (_) => SplashController(
        FakeCheckOnboardingSeenUseCase(),
        FakeValidateStoredSessionUseCase(status: status),
        minimumDisplayDuration: Duration.zero,
      ),
    );
