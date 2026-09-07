import 'package:click_seguro_app/modules/common/common.dart';
import 'package:click_seguro_app/modules/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:click_seguro_app/modules/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:click_seguro_app/modules/onboarding/domain/usecases/check_onboarding_seen_usecase.dart';
import 'package:click_seguro_app/modules/onboarding/domain/usecases/complete_onboarding_usecase.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/controller/onboarding_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingModule implements ModuleInterface {
  @override
  Future<void> registerServices(GetIt injector) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    injector.registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepositoryImpl(preferences),
    );
    injector.registerLazySingleton<CheckOnboardingSeenUseCase>(
      () => CheckOnboardingSeenUseCase(injector<OnboardingRepository>()),
    );
    injector.registerLazySingleton<CompleteOnboardingUseCase>(
      () => CompleteOnboardingUseCase(injector<OnboardingRepository>()),
    );
  }

  @override
  List<SingleChildWidget> providers(GetIt injector) {
    return [
      ChangeNotifierProvider(
        create: (_) => OnboardingController(injector<CompleteOnboardingUseCase>()),
      ),
    ];
  }
}
