import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/models/onboarding_page_content.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({super.key, required this.content});

  final OnboardingPageContent content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: content.iconBackgroundColor(context.colors),
              borderRadius: AppSpacing.radius3xl,
            ),
            child: Icon(
              content.icon,
              color: context.colors.textPrimaryForeground,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.s7),
          Text(
            content.titleKey.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            content.descriptionKey.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: context.colors.textMutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
