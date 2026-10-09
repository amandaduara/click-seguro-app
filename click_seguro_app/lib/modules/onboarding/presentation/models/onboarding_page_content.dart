import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
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

  /// Cor do círculo do ícone, lida da paleta do tema em uso (light ou alto
  /// contraste).
  final Color Function(AppPalette colors) iconBackgroundColor;
  final String titleKey;
  final String descriptionKey;
  final String buttonLabelKey;

  static const List<OnboardingPageContent> pages = [
    OnboardingPageContent(
      icon: LucideIcons.shield,
      iconBackgroundColor: _primary,
      titleKey: AppStrings.onboardingPage1Title,
      descriptionKey: AppStrings.onboardingPage1Description,
      buttonLabelKey: AppStrings.onboardingButtonContinue,
    ),
    OnboardingPageContent(
      icon: LucideIcons.newspaper,
      iconBackgroundColor: _secondary,
      titleKey: AppStrings.onboardingPage2Title,
      descriptionKey: AppStrings.onboardingPage2Description,
      buttonLabelKey: AppStrings.onboardingButtonContinue,
    ),
    OnboardingPageContent(
      icon: LucideIcons.graduationCap,
      iconBackgroundColor: _muted,
      titleKey: AppStrings.onboardingPage3Title,
      descriptionKey: AppStrings.onboardingPage3Description,
      buttonLabelKey: AppStrings.onboardingButtonStart,
    ),
  ];

  static Color _primary(AppPalette colors) => colors.primary;
  static Color _secondary(AppPalette colors) => colors.secondary;
  static Color _muted(AppPalette colors) => colors.textMutedForeground;
}
