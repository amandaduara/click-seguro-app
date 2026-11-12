import 'dart:async';

import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/splash/presentation/controller/splash_controller.dart';
import 'package:click_seguro_app/modules/splash/presentation/widgets/splash_scene_painter.dart';
import 'package:click_seguro_app/modules/splash/splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_splash_usecases.dart';

/// Conta quantas vezes a tela de destino foi montada.
class _Destination extends StatefulWidget {
  const _Destination(this.name, this.visits);

  final String name;
  final List<String> visits;

  @override
  State<_Destination> createState() => _DestinationState();
}

class _DestinationState extends State<_Destination> {
  @override
  void initState() {
    super.initState();
    widget.visits.add(widget.name);
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Text('tela ${widget.name}'));
}

void main() {
  late FakeCheckOnboardingSeenUseCase checkOnboarding;
  late FakeValidateStoredSessionUseCase validateSession;
  late List<String> visits;

  setUp(() {
    checkOnboarding = FakeCheckOnboardingSeenUseCase();
    validateSession = FakeValidateStoredSessionUseCase();
    visits = [];
  });

  GoRouter buildRouter({
    bool reduceMotion = false,
    ValueNotifier<bool>? motion,
  }) {
    final ValueNotifier<bool> reduced = motion ?? ValueNotifier(reduceMotion);
    return GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => ValueListenableBuilder<bool>(
            valueListenable: reduced,
            builder: (context, value, child) =>
                AppMotionScope(appReduceMotion: value, child: child!),
            child: ChangeNotifierProvider(
              create: (_) => SplashController(checkOnboarding, validateSession),
              child: const SplashPage(),
            ),
          ),
        ),
        for (final String name in ['onboarding', 'home', 'login'])
          GoRoute(
            path: '/$name',
            builder: (_, _) => _Destination(name, visits),
          ),
      ],
    );
  }

  SplashScenePainter scene(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.descendant(
                  of: find.byKey(SplashPage.sceneKey),
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is CustomPaint &&
                        widget.painter is SplashScenePainter,
                  ),
                ),
              )
              .painter!
          as SplashScenePainter;

  Future<void> pumpSplash(
    WidgetTester tester, {
    bool reduceMotion = false,
    ValueNotifier<bool>? motion,
    ThemeData? theme,
  }) => pumpLocalized(
    tester,
    router: buildRouter(reduceMotion: reduceMotion, motion: motion),
    theme: theme,
    settle: false,
  );

  group('texto e marca', () {
    testWidgets('mostra o nome e a frase de apoio enquanto decide', (
      tester,
    ) async {
      validateSession.completer = Completer<UserSessionStatus>();

      await pumpSplash(tester);

      expect(find.text('Click Seguro'), findsOneWidget);
      expect(find.byKey(SplashPage.logoKey), findsOneWidget);
      expect(find.text('Sua segurança em primeiro lugar'), findsOneWidget);

      validateSession.completer!.complete(UserSessionStatus.authenticated);
      await tester.pumpAndSettle();
    });

    testWidgets('marca oficial cabe em tela curta com fonte em 200%', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      validateSession.completer = Completer<UserSessionStatus>();

      await pumpSplash(tester);
      await tester.pump(const Duration(milliseconds: 1800));

      expect(find.byKey(SplashPage.logoKey), findsOneWidget);
      expect(find.text('Click Seguro'), findsOneWidget);
      expect(tester.takeException(), isNull);

      validateSession.completer!.complete(UserSessionStatus.authenticated);
      await tester.pumpAndSettle();
    });
  });

  group('destino', () {
    testWidgets('visto + conectada abre a área principal e sai da pilha', (
      tester,
    ) async {
      final router = buildRouter();

      await pumpLocalized(tester, router: router);

      expect(find.text('tela home'), findsOneWidget);
      expect(router.canPop(), isFalse);
    });

    testWidgets('visto + sem sessão abre o login', (tester) async {
      validateSession.status = UserSessionStatus.unauthenticated;

      await pumpLocalized(tester, router: buildRouter());

      expect(find.text('tela login'), findsOneWidget);
    });

    testWidgets('onboarding não visto abre o onboarding', (tester) async {
      checkOnboarding.result = const Right(false);

      await pumpLocalized(tester, router: buildRouter());

      expect(find.text('tela onboarding'), findsOneWidget);
    });
  });

  group('animação e validação', () {
    testWidgets('destino pronto na hora: só sai depois dos 1 800 ms', (
      tester,
    ) async {
      await pumpSplash(tester);

      await tester.pump(const Duration(milliseconds: 1799));
      expect(find.text('tela home'), findsNothing);
      expect(find.byKey(SplashPage.logoKey), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('tela home'), findsOneWidget);
    });

    testWidgets('validação demorando: fica na splash, respira e segue quando '
        'a validação termina', (tester) async {
      validateSession.completer = Completer<UserSessionStatus>();
      await pumpSplash(tester);

      await tester.pump(const Duration(milliseconds: 1800));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(scene(tester).t, 1);
      final double before = scene(tester).breath;

      await tester.pump(const Duration(milliseconds: 1300));
      final double after = scene(tester).breath;
      expect(after, isNot(before), reason: 'a marca respira');
      expect(find.byKey(SplashPage.logoKey), findsOneWidget);
      expect(find.text('tela login'), findsNothing);

      validateSession.completer!.complete(UserSessionStatus.unauthenticated);
      await tester.pumpAndSettle();
      expect(find.text('tela login'), findsOneWidget);
    });

    testWidgets('a marca não respira enquanto a animação ainda toca', (
      tester,
    ) async {
      validateSession.completer = Completer<UserSessionStatus>();
      await pumpSplash(tester);

      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 600));

      expect(scene(tester).breath, 0);

      validateSession.completer!.complete(UserSessionStatus.authenticated);
      await tester.pumpAndSettle();
    });

    testWidgets('navega uma única vez, com a validação pronta antes da '
        'animação', (tester) async {
      await pumpSplash(tester);

      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      expect(visits, ['home']);
      expect(validateSession.calls, 1);
      expect(checkOnboarding.calls, 1);
    });

    testWidgets('navega uma única vez, com a validação pronta depois da '
        'animação', (tester) async {
      validateSession.completer = Completer<UserSessionStatus>();
      await pumpSplash(tester);

      await tester.pump(const Duration(milliseconds: 2500));
      expect(visits, isEmpty);
      validateSession.completer!.complete(UserSessionStatus.authenticated);
      await tester.pumpAndSettle();

      expect(visits, ['home']);
      expect(validateSession.calls, 1);
    });
  });

  group('acessibilidade e tema', () {
    testWidgets('leitor de tela: um único nó com o nome e a frase', (
      tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      validateSession.completer = Completer<UserSessionStatus>();
      await pumpSplash(tester);
      await tester.pump(const Duration(milliseconds: 1800));

      expect(find.bySemanticsLabel(RegExp('Click Seguro')), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Sua segurança em primeiro lugar')),
        findsOneWidget,
      );
      final SemanticsNode node = tester.getSemantics(
        find.byKey(SplashPage.sceneKey),
      );
      expect(node.label, contains('Click Seguro'));
      expect(node.label, contains('Sua segurança em primeiro lugar'));

      validateSession.completer!.complete(UserSessionStatus.authenticated);
      await tester.pumpAndSettle();
      semantics.dispose();
    });

    testWidgets('a cena usa só as cores do tema (alto contraste incluso)', (
      tester,
    ) async {
      validateSession.completer = Completer<UserSessionStatus>();
      await pumpSplash(tester, theme: AppTheme.highContrastTheme);
      await tester.pump(const Duration(milliseconds: 1800));

      final SplashScenePainter painter = scene(tester);
      expect(painter.colors.primary, AppPalette.highContrast.primary);
      expect(painter.colors.primaryGlow, AppPalette.highContrast.primaryGlow);
      expect(painter.colors.background, AppPalette.highContrast.background);
      expect(
        tester.widget<Text>(find.text('Click Seguro')).style?.color,
        AppPalette.highContrast.secondary,
      );
      expect(
        tester
            .widget<Text>(find.text('Sua segurança em primeiro lugar'))
            .style
            ?.color,
        AppPalette.highContrast.textMutedForeground,
      );

      validateSession.completer!.complete(UserSessionStatus.authenticated);
      await tester.pumpAndSettle();
    });
  });

  group('movimento reduzido', () {
    testWidgets('destino pronto: navega no primeiro quadro, sem esperar os '
        '1 800 ms', (tester) async {
      await pumpSplash(tester, reduceMotion: true);

      await tester.pump(const Duration(milliseconds: 16));
      await tester.pumpAndSettle(const Duration(milliseconds: 16));

      expect(find.text('tela home'), findsOneWidget);
      expect(visits, ['home']);
    });

    testWidgets('validação demorando: mostra o estado final e nada se move', (
      tester,
    ) async {
      validateSession.completer = Completer<UserSessionStatus>();
      await pumpSplash(tester, reduceMotion: true);
      await tester.pump(const Duration(milliseconds: 16));

      final Size logo = tester.getSize(find.byKey(SplashPage.logoKey));
      expect(scene(tester).t, 1);
      expect(scene(tester).breath, 0);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));

      expect(scene(tester).t, 1);
      expect(scene(tester).breath, 0, reason: 'a marca não respira');
      expect(tester.getSize(find.byKey(SplashPage.logoKey)), logo);
      expect(find.text('Click Seguro'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);

      validateSession.completer!.complete(UserSessionStatus.authenticated);
      await tester.pumpAndSettle();
      expect(find.text('tela home'), findsOneWidget);
    });

    testWidgets('o nome e a frase já aparecem inteiros, sem entrada', (
      tester,
    ) async {
      validateSession.completer = Completer<UserSessionStatus>();
      await pumpSplash(tester, reduceMotion: true);
      await tester.pump(const Duration(milliseconds: 16));

      for (final String text in [
        'Click Seguro',
        'Sua segurança em primeiro lugar',
      ]) {
        final Opacity rise = tester.widget(
          find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
        );
        expect(rise.opacity, 1);
      }

      validateSession.completer!.complete(UserSessionStatus.authenticated);
      await tester.pumpAndSettle();
    });

    testWidgets('ligado durante a animação, pula para o estado final', (
      tester,
    ) async {
      validateSession.completer = Completer<UserSessionStatus>();
      final ValueNotifier<bool> motion = ValueNotifier(false);
      await pumpSplash(tester, motion: motion);

      await tester.pump(const Duration(milliseconds: 600));
      expect(scene(tester).t, lessThan(1));

      motion.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(scene(tester).t, 1);
      expect(scene(tester).breath, 0);

      await tester.pump(const Duration(seconds: 3));
      expect(scene(tester).breath, 0, reason: 'sem respirar');

      validateSession.completer!.complete(UserSessionStatus.authenticated);
      await tester.pumpAndSettle();
      expect(find.text('tela home'), findsOneWidget);
    });

    testWidgets('ligado depois da animação, a marca para de respirar', (
      tester,
    ) async {
      validateSession.completer = Completer<UserSessionStatus>();
      final ValueNotifier<bool> motion = ValueNotifier(false);
      await pumpSplash(tester, motion: motion);
      await tester.pump(const Duration(milliseconds: 1800));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 700));
      expect(scene(tester).breath, greaterThan(0));

      motion.value = true;
      await tester.pump();
      final double frozen = scene(tester).breath;
      await tester.pump(const Duration(seconds: 2));

      expect(scene(tester).breath, frozen);

      validateSession.completer!.complete(UserSessionStatus.authenticated);
      await tester.pumpAndSettle();
    });
  });
}
