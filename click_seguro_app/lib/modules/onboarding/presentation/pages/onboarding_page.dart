import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/controller/onboarding_controller.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/models/onboarding_page_content.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/widgets/onboarding_page_indicator.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/widgets/onboarding_slide.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleSkip(OnboardingController controller) async {
    await controller.skip();
    if (mounted) context.go('/login');
  }

  Future<void> _handleNext(OnboardingController controller) async {
    final bool finished = await controller.next();
    if (finished) {
      if (mounted) context.go('/login');
      return;
    }
    if (!mounted) return;
    final Duration duration = AppMotion.of(context).long;
    if (duration == Duration.zero) {
      _pageController.jumpToPage(controller.currentPage);
      return;
    }
    await _pageController.animateToPage(
      controller.currentPage,
      duration: duration,
      curve: AppMotion.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final OnboardingController controller = context
        .watch<OnboardingController>();
    final OnboardingPageContent currentContent =
        OnboardingPageContent.pages[controller.currentPage];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: TextButton(
                  onPressed: () => _handleSkip(controller),
                  child: Text(AppStrings.onboardingSkip.tr()),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: controller.onPageChanged,
                children: OnboardingPageContent.pages
                    .map((content) => OnboardingSlide(content: content))
                    .toList(),
              ),
            ),
            OnboardingPageIndicator(
              pageCount: OnboardingPageContent.pages.length,
              currentPage: controller.currentPage,
              controller: _pageController,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s6),
              // "Continuar" vira "Começar" esmaecendo; o fundo é o mesmo,
              // então só o rótulo parece trocar.
              child: AnimatedSwitcher(
                duration: AppMotion.of(context).medium,
                switchInCurve: AppMotion.enter,
                switchOutCurve: AppMotion.exit,
                child: SafeButton(
                  key: ValueKey(currentContent.buttonLabelKey),
                  label: currentContent.buttonLabelKey.tr(),
                  iconRight: const Icon(LucideIcons.chevronRight, size: 16),
                  onPressed: () => _handleNext(controller),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
