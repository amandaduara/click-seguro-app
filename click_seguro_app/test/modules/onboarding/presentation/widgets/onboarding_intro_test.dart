import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/widgets/brand_mark.dart';
import 'package:click_seguro_app/core/widgets/brand_scene.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences_notifier.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
import 'package:click_seguro_app/modules/onboarding/domain/usecases/complete_onboarding_usecase.dart';
import 'package:click_seguro_app/modules/onboarding/onboarding.dart';
import 'package:click_seguro_app/modules/onboarding/presentation/controller/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../fakes/fake_text_to_speech_service.dart';
import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_onboarding_repository.dart';

const Size _phone = Size(390, 844);

/// Passagem da splash para o onboarding (specs/026 US5, FR-020 e FR-022).
void main() {
  late FakeOnboardingRepository repository;

  setUp(() {
    repository = FakeOnboardingRepository();
    final AccessibilityPreferencesNotifier preferences =
        AccessibilityPreferencesNotifier();
    GetIt.instance
      ..registerSingleton(preferences)
      ..registerFactory(
        () => ReadAloudController(
          FakeTextToSpeechService(),
          preferences: preferences,
        ),
      );
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> pumpOnboarding(
    WidgetTester tester, {
    bool fromSplash = true,
    bool reduceMotion = false,
  }) async {
    tester.view
      ..physicalSize = _phone * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpLocalized(
      tester,
      settle: false,
      router: GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => AppMotionScope(
              appReduceMotion: reduceMotion,
              child: ChangeNotifierProvider(
                create: (_) =>
                    OnboardingController(CompleteOnboardingUseCase(repository)),
                child: OnboardingPage(fromSplash: fromSplash),
              ),
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(body: Text('login')),
          ),
        ],
      ),
    );
  }

  /// Opacidade efetiva do texto [text] (produto das `Opacity` acima dele).
  double opacityOf(WidgetTester tester, String text) => tester
      .widgetList<Opacity>(
        find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
      )
      .fold(1, (value, widget) => value * widget.opacity);

  final Finder splashLogo = find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is BrandMarkPainter,
  );

  testWidgets('quadro 0: a marca, o nome e a onda onde a splash parou', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    final Rect logo = BrandScene.logoRectFor(
      width: _phone.width,
      viewportHeight: _phone.height,
    );
    final Rect painted = tester.getRect(splashLogo);
    expect(painted.left, closeTo(logo.left, 0.5));
    expect(painted.top, closeTo(logo.top, 0.5));
    expect(painted.width, closeTo(logo.width, 0.5));
    expect(
      tester.getTopLeft(find.text('Click Seguro')).dy,
      closeTo(BrandScene.titleTopFor(logo), 0.5),
    );
    expect(tester.getBottomLeft(find.byType(BrandWave)).dy, _phone.height);
    expect(opacityOf(tester, 'Proteja-se de golpes'), 0);
  });

  testWidgets('a onda desce e sai; a marca e o nome somem', (tester) async {
    await pumpOnboarding(tester);

    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.getTopLeft(find.byType(BrandWave)).dy,
      greaterThan(_phone.height - BrandScene.glowFooterHeight),
      reason: 'descendo',
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(BrandWave), findsNothing);
    expect(splashLogo, findsNothing);
    expect(find.text('Click Seguro'), findsNothing);
  });

  testWidgets('o slide entra em sequência; em 1 s está tudo pronto', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    await tester.pump(const Duration(milliseconds: 600));
    expect(opacityOf(tester, 'Proteja-se de golpes'), greaterThan(0));
    expect(opacityOf(tester, 'Pular'), 0);

    await tester.pump(const Duration(milliseconds: 400));
    for (final String text in [
      'Proteja-se de golpes',
      'Receba alertas sobre os golpes mais comuns e aprenda a se defender.',
      'Continuar',
      'Pular',
    ]) {
      expect(opacityOf(tester, text), 1, reason: text);
    }
  });

  testWidgets('toques bloqueados até o slide terminar de entrar', (
    tester,
  ) async {
    await pumpOnboarding(tester);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.tap(find.text('Pular'), warnIfMissed: false);
    await tester.pump();
    expect(repository.seen, isFalse);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Pular'));
    await tester.pumpAndSettle();
    expect(find.text('login'), findsOneWidget);
  });

  testWidgets('o nome e o slogan da splash ficam fora do leitor de tela', (
    tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpOnboarding(tester);

    expect(find.bySemanticsLabel('Click Seguro'), findsNothing);
    handle.dispose();
  });

  testWidgets('movimento reduzido: o onboarding aparece pronto', (
    tester,
  ) async {
    await pumpOnboarding(tester, reduceMotion: true);

    expect(find.text('Click Seguro'), findsNothing);
    expect(find.byType(BrandWave), findsNothing);
    expect(opacityOf(tester, 'Proteja-se de golpes'), 1);
    expect(opacityOf(tester, 'Pular'), 1);
  });

  testWidgets('sem vir da splash: sem abertura', (tester) async {
    await pumpOnboarding(tester, fromSplash: false);

    expect(find.text('Click Seguro'), findsNothing);
    expect(find.byType(BrandWave), findsNothing);
    expect(opacityOf(tester, 'Proteja-se de golpes'), 1);
  });
}
