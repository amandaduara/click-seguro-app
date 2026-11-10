import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    super.key,
    required this.pageCount,
    required this.currentPage,
  });

  final int pageCount;
  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(pageCount, (index) {
        final bool isActive = index == currentPage;
        return AnimatedContainer(
          duration: AppMotion.duration(
            AppMotion.standard,
            reduce: context.reduceMotion,
          ),
          margin: const EdgeInsets.only(right: AppSpacing.s2),
          width: isActive ? 32 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive ? context.colors.primary : context.colors.border,
            borderRadius: AppSpacing.radiusFull,
          ),
        );
      }),
    );
  }
}
