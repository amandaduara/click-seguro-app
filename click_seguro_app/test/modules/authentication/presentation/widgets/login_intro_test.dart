import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/widgets/app_logo.dart';
import 'package:click_seguro_app/core/widgets/brand_mark.dart';
import 'package:click_seguro_app/core/widgets/brand_scene.dart';
import 'package:click_seguro_app/modules/authentication/presentation/controller/authentication_controller.dart';
import 'package:click_seguro_app/modules/authentication/presentation/pages/login_page.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/auth_header.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/login_intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/controller_factory.dart';
import '../../fakes/fake_auth_repository.dart';

const Size _phone = Size(390, 844);

void main() {
  late FakeAuthRepository repository;
  late AuthenticationController controller;

  setUp(() {
    repository = FakeAuthRepository();
    controller = buildAuthenticationController(repository);
  });

  /// O login aberto pela splash, num celular de 390 × 844, no quadro 0 da
  /// abertura (sem esperar as animações).
  Future<void> pumpFromSplash(
    WidgetTester tester, {
    LoginIntroOrigin? origin = LoginIntroOrigin.splash,
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
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (_, _) => AppMotionScope(
              appReduceMotion: reduceMotion,
              child: ChangeNotifierProvider.value(
                value: controller,
                child: LoginPage(introFrom: origin),
              ),
            ),
          ),
          GoRoute(path: '/home', builder: (_, _) => const Text('HOME')),
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

  final Finder flying = find.byType(BrandMark);
  final Finder headerLogo = find.descendant(
    of: find.byType(AuthHeader),
    matching: find.byType(AppLogo),
  );

  testWidgets('quadro 0: a marca e o nome da splash onde a splash parou', (
    tester,
  ) async {
    await pumpFromSplash(tester);

    final Rect start = BrandScene.logoRectFor(
      width: _phone.width,
      viewportHeight: _phone.height,
    );
    final Rect rect = tester.getRect(flying);
    expect(rect.left, closeTo(start.left, 0.5));
    expect(rect.top, closeTo(start.top, 0.5));
    expect(rect.width, closeTo(start.width, 0.5));
    expect(find.text('Click Seguro'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Click Seguro')).dy,
      closeTo(BrandScene.titleTopFor(start), 0.5),
    );
    expect(opacityOf(tester, 'Continuar sem login'), 0);
  });

  testWidgets('em 750 ms a marca chega ao cabeçalho e assume o lugar dela', (
    tester,
  ) async {
    await pumpFromSplash(tester);
    final Rect target = tester.getRect(headerLogo);

    await tester.pump(const Duration(milliseconds: 740));
    final Rect rect = tester.getRect(flying);
    expect(rect.center.dx, closeTo(target.center.dx, 3));
    expect(rect.center.dy, closeTo(target.center.dy, 3));
    expect(rect.width, closeTo(target.width, 3));

    await tester.pump(const Duration(milliseconds: 20));
    expect(flying, findsNothing);
    expect(find.text('Click Seguro'), findsNothing);
  });

  testWidgets('os itens entram em sequência; em 1 250 ms está tudo pronto', (
    tester,
  ) async {
    await pumpFromSplash(tester);

    await tester.pump(const Duration(milliseconds: 600));
    expect(opacityOf(tester, 'Bem-vindo ao Click Seguro'), greaterThan(0));
    expect(opacityOf(tester, 'Continuar sem login'), 0);

    await tester.pump(const Duration(milliseconds: 650));
    for (final String text in [
      'Bem-vindo ao Click Seguro',
      'E-mail',
      'Esqueci minha senha',
      'Continuar sem login',
    ]) {
      expect(opacityOf(tester, text), 1, reason: text);
    }
  });

  testWidgets('toques ficam bloqueados até a abertura terminar', (
    tester,
  ) async {
    await pumpFromSplash(tester);

    await tester.pump(const Duration(milliseconds: 1000));
    await tester.tap(find.text('Continuar sem login'), warnIfMissed: false);
    await tester.pump();
    expect(repository.guestCalls, 0);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Continuar sem login'));
    await tester.pumpAndSettle();
    expect(repository.guestCalls, 1);
  });

  testWidgets('o nome e o slogan da splash ficam fora do leitor de tela', (
    tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpFromSplash(tester);

    expect(find.bySemanticsLabel('Click Seguro'), findsNothing);
    expect(
      find.bySemanticsLabel('Sua segurança em primeiro lugar'),
      findsNothing,
    );
    handle.dispose();
  });

  testWidgets('movimento reduzido: o login aparece pronto no quadro 0', (
    tester,
  ) async {
    await pumpFromSplash(tester, reduceMotion: true);

    expect(flying, findsNothing);
    expect(find.text('Click Seguro'), findsNothing);
    expect(opacityOf(tester, 'Continuar sem login'), 1);
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(of: headerLogo, matching: find.byType(Opacity)).first,
          )
          .opacity,
      1,
    );
  });

  testWidgets('sem vir da splash: sem abertura', (tester) async {
    await pumpFromSplash(tester, origin: null);

    expect(flying, findsNothing);
    expect(find.text('Click Seguro'), findsNothing);
    expect(opacityOf(tester, 'Continuar sem login'), 1);
  });

  // specs/026 US5 (FR-021): vindo do onboarding, sem voo nem nome da splash;
  // a onda sobe do pé da tela e a marca do cabeçalho cresce.
  group('vindo do onboarding', () {
    double waveTop(WidgetTester tester) =>
        tester.getTopLeft(find.byType(BrandWave)).dy;

    testWidgets('quadro 0: sem voo, onda abaixo da tela e marca invisível', (
      tester,
    ) async {
      await pumpFromSplash(tester, origin: LoginIntroOrigin.onboarding);

      expect(flying, findsNothing);
      expect(find.text('Click Seguro'), findsNothing);
      expect(waveTop(tester), closeTo(_phone.height, 1));
      expect(
        tester
            .widgetList<Opacity>(
              find.ancestor(of: headerLogo, matching: find.byType(Opacity)),
            )
            .fold<double>(1, (value, widget) => value * widget.opacity),
        0,
      );
    });

    testWidgets('a onda chega ao pé da tela em 500 ms e a marca aparece', (
      tester,
    ) async {
      await pumpFromSplash(tester, origin: LoginIntroOrigin.onboarding);

      await tester.pump(const Duration(milliseconds: 250));
      expect(waveTop(tester), lessThan(_phone.height - 1));
      expect(
        waveTop(tester),
        greaterThan(_phone.height - BrandScene.glowFooterHeight),
      );

      await tester.pump(const Duration(milliseconds: 350));
      expect(
        tester.getBottomLeft(find.byType(BrandWave)).dy,
        closeTo(_phone.height, 0.5),
      );
      expect(
        tester
            .widgetList<Opacity>(
              find.ancestor(of: headerLogo, matching: find.byType(Opacity)),
            )
            .fold<double>(1, (value, widget) => value * widget.opacity),
        1,
      );
    });

    testWidgets('blocos em sequência; pronto e tocável em 1 250 ms', (
      tester,
    ) async {
      await pumpFromSplash(tester, origin: LoginIntroOrigin.onboarding);

      await tester.pump(const Duration(milliseconds: 600));
      expect(opacityOf(tester, 'Continuar sem login'), 0);

      await tester.pump(const Duration(milliseconds: 700));
      expect(opacityOf(tester, 'Continuar sem login'), 1);
      await tester.tap(find.text('Continuar sem login'));
      await tester.pumpAndSettle();
      expect(repository.guestCalls, 1);
    });

    testWidgets('movimento reduzido: pronto no quadro 0', (tester) async {
      await pumpFromSplash(
        tester,
        origin: LoginIntroOrigin.onboarding,
        reduceMotion: true,
      );

      expect(
        tester.getBottomLeft(find.byType(BrandWave)).dy,
        closeTo(_phone.height, 0.5),
      );
      expect(opacityOf(tester, 'Continuar sem login'), 1);
    });
  });
}
