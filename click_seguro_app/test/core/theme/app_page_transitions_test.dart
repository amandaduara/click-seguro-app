import 'dart:async';

import 'package:click_seguro_app/core/routing/app_fade_page.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Transições de página (specs/022 R4): animadas por padrão; com o
/// movimento reduzido, a tela nova aparece no primeiro quadro e a que sai
/// some no primeiro quadro da volta.
void main() {
  Future<GoRouter> pumpApp(WidgetTester tester, {required bool reduce}) async {
    final GoRouter router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('início')),
          routes: [
            GoRoute(
              path: 'detail',
              builder: (_, _) => const Scaffold(body: Text('detalhe')),
            ),
          ],
        ),
        GoRoute(
          path: '/login',
          pageBuilder: (_, state) =>
              appFadePage(state, const Scaffold(body: Text('login'))),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
        builder: (context, child) =>
            AppMotionScope(appReduceMotion: reduce, child: child!),
      ),
    );
    return router;
  }

  bool visible(WidgetTester tester, String text) =>
      find.text(text).hitTestable().evaluate().isNotEmpty;

  const variant = TargetPlatformVariant({
    TargetPlatform.android,
    TargetPlatform.iOS,
  });

  testWidgets('push animado: a transição leva mais de um quadro', (
    tester,
  ) async {
    final GoRouter router = await pumpApp(tester, reduce: false);

    unawaited(router.push('/detail'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(visible(tester, 'detalhe'), isTrue);
  }, variant: variant);

  testWidgets('reduzido: entra e sai no primeiro quadro', (tester) async {
    final GoRouter router = await pumpApp(tester, reduce: true);

    unawaited(router.push('/detail'));
    await tester.pump();
    await tester.pump();
    expect(visible(tester, 'detalhe'), isTrue);
    expect(visible(tester, 'início'), isFalse);

    router.pop();
    await tester.pump();
    await tester.pump();
    expect(visible(tester, 'detalhe'), isFalse);
    expect(visible(tester, 'início'), isTrue);
    await tester.pumpAndSettle();
  }, variant: variant);

  group('appFadePage', () {
    double opacityOf(WidgetTester tester, String text) => tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.text(text),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;

    testWidgets('esmaece em AppMotion.medium', (tester) async {
      final GoRouter router = await pumpApp(tester, reduce: false);

      router.go('/login');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(opacityOf(tester, 'login'), inExclusiveRange(0, 1));

      await tester.pumpAndSettle();
      expect(opacityOf(tester, 'login'), 1);
    });

    testWidgets('reduzido: sem esmaecer', (tester) async {
      final GoRouter router = await pumpApp(tester, reduce: true);

      router.go('/login');
      await tester.pump();
      await tester.pump();

      expect(visible(tester, 'login'), isTrue);
      expect(
        find.ancestor(
          of: find.text('login'),
          matching: find.byWidgetPredicate(
            (w) => w is FadeTransition && w.opacity.value < 1,
          ),
        ),
        findsNothing,
      );
      await tester.pumpAndSettle();
    });
  });
}
