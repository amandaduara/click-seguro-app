import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/widgets/press_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    bool reduce = false,
    bool enabled = true,
    VoidCallback? onTap,
  }) => tester.pumpWidget(
    MaterialApp(
      home: AppMotionScope(
        appReduceMotion: reduce,
        child: Scaffold(
          body: Center(
            child: PressScale(
              enabled: enabled,
              pressedScale: 0.9,
              onTap: onTap ?? () {},
              child: const ColoredBox(
                color: Colors.blue,
                child: SizedBox(width: 100, height: 50),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  double scale(WidgetTester tester) => tester
      .widget<ScaleTransition>(
        find.descendant(
          of: find.byType(PressScale),
          matching: find.byType(ScaleTransition),
        ),
      )
      .scale
      .value;

  testWidgets('toque curto ainda afunda por inteiro e depois volta (FR-020)', (
    tester,
  ) async {
    var taps = 0;
    await pump(tester, onTap: () => taps++);

    await tester.tap(find.byType(PressScale));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(scale(tester), lessThan(1));

    await tester.pump(const Duration(milliseconds: 60));
    expect(scale(tester), closeTo(0.9, 0.001));

    await tester.pumpAndSettle();
    expect(scale(tester), 1);
    expect(taps, 1);
  });

  testWidgets('segurar mantém afundado até soltar', (tester) async {
    await pump(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PressScale)),
    );
    await tester.pumpAndSettle();
    expect(scale(tester), closeTo(0.9, 0.001));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(scale(tester), 1);
  });

  testWidgets('desabilitado não afunda nem chama o toque', (tester) async {
    var taps = 0;
    await pump(tester, enabled: false, onTap: () => taps++);

    await tester.tap(find.byType(PressScale));
    await tester.pump(const Duration(milliseconds: 50));

    expect(scale(tester), 1);
    expect(taps, 0);
  });

  testWidgets('com "Reduzir animações", nada fica afundado', (tester) async {
    await pump(tester, reduce: true);

    await tester.tap(find.byType(PressScale));
    await tester.pump();

    expect(scale(tester), 1);
  });
}
