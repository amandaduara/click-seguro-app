import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/illustrations/app_illustration.dart';

/// Um slide do onboarding (RF-002): ilustração do redesign 2.0 e as chaves
/// dos textos, que não mudam.
class OnboardingPageContent {
  const OnboardingPageContent({
    required this.illustration,
    required this.titleKey,
    required this.descriptionKey,
    required this.buttonLabelKey,
  });

  final AppIllustration illustration;
  final String titleKey;
  final String descriptionKey;
  final String buttonLabelKey;

  static const List<OnboardingPageContent> pages = [
    OnboardingPageContent(
      illustration: AppIllustration.onboardingProtect,
      titleKey: AppStrings.onboardingPage1Title,
      descriptionKey: AppStrings.onboardingPage1Description,
      buttonLabelKey: AppStrings.onboardingButtonContinue,
    ),
    OnboardingPageContent(
      illustration: AppIllustration.onboardingNews,
      titleKey: AppStrings.onboardingPage2Title,
      descriptionKey: AppStrings.onboardingPage2Description,
      buttonLabelKey: AppStrings.onboardingButtonContinue,
    ),
    OnboardingPageContent(
      illustration: AppIllustration.onboardingPractice,
      titleKey: AppStrings.onboardingPage3Title,
      descriptionKey: AppStrings.onboardingPage3Description,
      buttonLabelKey: AppStrings.onboardingButtonStart,
    ),
  ];
}
