import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OnboardingPageContent {
  const OnboardingPageContent({
    required this.icon,
    required this.iconBackgroundColor,
    required this.titleKey,
    required this.descriptionKey,
    required this.buttonLabelKey,
  });

  final IconData icon;
  final Color iconBackgroundColor;
  final String titleKey;
  final String descriptionKey;
  final String buttonLabelKey;

  static const List<OnboardingPageContent> pages = [
    OnboardingPageContent(
      icon: LucideIcons.shield,
      iconBackgroundColor: AppColors.primary,
      titleKey: AppStrings.onboardingPage1Title,
      descriptionKey: AppStrings.onboardingPage1Description,
      buttonLabelKey: AppStrings.onboardingButtonContinue,
    ),
    OnboardingPageContent(
      icon: LucideIcons.newspaper,
      iconBackgroundColor: AppColors.secondary,
      titleKey: AppStrings.onboardingPage2Title,
      descriptionKey: AppStrings.onboardingPage2Description,
      buttonLabelKey: AppStrings.onboardingButtonContinue,
    ),
    OnboardingPageContent(
      icon: LucideIcons.graduationCap,
      iconBackgroundColor: AppColors.textMutedForeground,
      titleKey: AppStrings.onboardingPage3Title,
      descriptionKey: AppStrings.onboardingPage3Description,
      buttonLabelKey: AppStrings.onboardingButtonStart,
    ),
  ];
}
