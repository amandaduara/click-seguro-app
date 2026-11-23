import 'dart:async';

import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/intro_reveal.dart';
import 'package:click_seguro_app/core/widgets/listen_button.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/controller/onboarding_controller.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/models/onboarding_page_content.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/widgets/onboarding_intro.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/widgets/onboarding_page_indicator.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/widgets/onboarding_slide.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/utils/motion_scroll.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.fromSplash = false});

  /// Aberto pela splash: faz a entrada animada ([OnboardingIntro]).
  final bool fromSplash;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  /// Quanto o onboarding desliza para a esquerda ao sair (specs/026 US5).
  static const double _exitSlide = 48;

  final PageController _pageController = PageController();

  /// Saída para o login: desliza para a esquerda e some.
  late final AnimationController _exit = AnimationController(vsync: this);
  final ReadAloudController _readAloud = GetIt.instance<ReadAloudController>();
  Locale? _locale;

  /// Slide já lido pela leitura automática (cada um, uma vez ao aparecer).
  int? _autoReadSlide;

  @override
  void initState() {
    super.initState();
    _readAloud.addListener(_maybeAutoRead);
  }

  /// O idioma da voz é o do app: prepara de novo se ele mudar.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Locale locale = context.locale;
    if (locale == _locale) return;
    _locale = locale;
    unawaited(_readAloud.prepare(locale));
  }

  @override
  void dispose() {
    _readAloud.removeListener(_maybeAutoRead);
    _readAloud.dispose();
    _pageController.dispose();
    _exit.dispose();
    super.dispose();
  }

  int get _currentSlide => context.read<OnboardingController>().currentPage;

  /// Com a leitura automática ligada, lê o slide atual quando a voz fica
  /// pronta ou quando ele aparece.
  void _maybeAutoRead() {
    if (!mounted ||
        _autoReadSlide == _currentSlide ||
        !_readAloud.isAvailable ||
        !GetIt.instance<AccessibilityPreferencesNotifier>()
            .value
            .autoReadAloud) {
      return;
    }
    _autoReadSlide = _currentSlide;
    unawaited(
      _readAloud.speak(OnboardingPageContent.pages[_currentSlide].spokenText),
    );
  }

  /// Trocar de slide para a leitura do anterior.
  void _onPageChanged(OnboardingController controller, int page) {
    controller.onPageChanged(page);
    unawaited(_readAloud.stop());
    _maybeAutoRead();
  }

  void _toggleListen(OnboardingPageContent content) => unawaited(
    _readAloud.isSpeaking
        ? _readAloud.stop()
        : _readAloud.speak(content.spokenText),
  );

  Future<void> _handleSkip(OnboardingController controller) async {
    await controller.skip();
    await _goToLogin();
  }

  Future<void> _handleNext(OnboardingController controller) async {
    final bool finished = await controller.next();
    if (finished) {
      await _goToLogin();
      return;
    }
    if (!mounted) return;
    await _pageController.moveToPage(
      controller.currentPage,
      duration: AppMotion.of(context).long,
    );
  }

  /// O onboarding desliza para a esquerda e some; o login faz a própria
  /// entrada, com a onda subindo (specs/026 US5, FR-021). Com o movimento
  /// reduzido, vai direto.
  Future<void> _goToLogin() async {
    if (!mounted) return;
    final AppMotion motion = AppMotion.of(context);
    if (!motion.reduced) {
      _exit.duration = motion.long;
      await _exit.forward();
    }
    if (mounted) context.go('/login?from=onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final OnboardingController controller = context
        .watch<OnboardingController>();
    final OnboardingPageContent currentContent =
        OnboardingPageContent.pages[controller.currentPage];

    // Redesign 2.0 (Figma, quadro 02): "Pular" no topo, o slide,
    // o indicador alinhado ao texto e o botão principal embaixo.
    final Widget content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s5,
              AppSpacing.s3,
              AppSpacing.s5,
              0,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              // Botão de texto: o leitor de tela anuncia "botão", não um
              // filtro (alvo de 48 dp do tamanho compacto).
              child: IntroReveal(
                interval: OnboardingIntroTimeline.skip,
                child: SafeButton(
                  label: AppStrings.onboardingSkip.tr(),
                  size: SafeButtonSize.compact,
                  tone: SafeButtonTone.link,
                  onPressed: () => _handleSkip(controller),
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => _onPageChanged(controller, page),
              children: [
                for (final content in OnboardingPageContent.pages)
                  OnboardingSlide(
                    content: content,
                    listen: ListenableBuilder(
                      listenable: _readAloud,
                      builder: (context, _) => _readAloud.isAvailable
                          ? ListenButton(
                              isSpeaking: _readAloud.isSpeaking,
                              onPressed: () => _toggleListen(content),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s6,
              AppSpacing.s4,
              AppSpacing.s6,
              0,
            ),
            child: IntroReveal(
              interval: OnboardingIntroTimeline.dots,
              child: OnboardingPageIndicator(
                pageCount: OnboardingPageContent.pages.length,
                currentPage: controller.currentPage,
                controller: _pageController,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s6,
              AppSpacing.s6,
              AppSpacing.s6,
              AppSpacing.s7,
            ),
            // "Continuar" vira "Começar" esmaecendo; o fundo é o mesmo,
            // então só o rótulo parece trocar.
            child: IntroReveal(
              interval: OnboardingIntroTimeline.button,
              child: AnimatedSwitcher(
                duration: AppMotion.of(context).medium,
                switchInCurve: AppMotion.enter,
                switchOutCurve: AppMotion.exit,
                child: SafeButton(
                  key: ValueKey(currentContent.buttonLabelKey),
                  label: currentContent.buttonLabelKey.tr(),
                  iconRight: const Icon(LucideIcons.arrowRight),
                  onPressed: () => _handleNext(controller),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // A saída: desliza para a esquerda e some, sem aceitar mais toques.
    final Widget leaving = AnimatedBuilder(
      animation: _exit,
      child: content,
      builder: (context, child) {
        final double progress = AppMotion.exit.transform(_exit.value);
        return IgnorePointer(
          ignoring: progress > 0,
          child: Opacity(
            opacity: 1 - progress,
            child: Transform.translate(
              offset: Offset(-_exitSlide * progress, 0),
              child: child,
            ),
          ),
        );
      },
    );

    return Scaffold(
      body: widget.fromSplash ? OnboardingIntro(child: leaving) : leaving,
    );
  }
}
