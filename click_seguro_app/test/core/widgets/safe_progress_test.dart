import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/widgets/safe_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'component_test_app.dart';

/// Barra, anel e segmentos de progresso: enchem em 400 ms (FR-020) ou
/// aparecem cheios com reduzir animações (FR-021).
void main() {
  double barFill(WidgetTester tester) => tester
      .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
      .widthFactor!;

  group('SafeProgressBar', () {
    testWidgets('enche até o valor em 400 ms', (tester) async {
      await pumpComponent(tester, const SafeProgressBar(value: 0.6));

      expect(barFill(tester), lessThan(0.6));
      await tester.pump(const Duration(milliseconds: 400));
      expect(barFill(tester), closeTo(0.6, 0.001));
    });

    testWidgets('com reduzir animações, já aparece cheia', (tester) async {
      await pumpComponent(
        tester,
        const SafeProgressBar(value: 0.6),
        disableAnimations: true,
      );

      expect(barFill(tester), closeTo(0.6, 0.001));
    });

    testWidgets('tom de sucesso usa o verde', (tester) async {
      await pumpComponent(
        tester,
        const SafeProgressBar(value: 1, tone: SafeProgressTone.success),
        disableAnimations: true,
      );

      final DecoratedBox fill = tester.widget(
        find.descendant(
          of: find.byType(FractionallySizedBox),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(
        (fill.decoration as BoxDecoration).color,
        AppPalette.light.success,
      );
    });

    testWidgets('valor fora de 0–1 é limitado', (tester) async {
      await pumpComponent(
        tester,
        const SafeProgressBar(value: 1.7),
        disableAnimations: true,
      );

      expect(barFill(tester), 1);
    });
  });

  group('SafeProgressRing', () {
    testWidgets('mostra o rótulo no centro, com 104 de lado', (tester) async {
      await pumpComponent(
        tester,
        const SafeProgressRing(value: 0.4, label: '40%'),
        disableAnimations: true,
      );

      expect(find.text('40%'), findsOneWidget);
      expect(
        tester.getSize(find.byType(SafeProgressRing)),
        const Size(104, 104),
      );
    });
  });

  group('SafeSegmentedProgress', () {
    testWidgets('um segmento por pergunta: feitos, atual e futuros', (
      tester,
    ) async {
      await pumpComponent(
        tester,
        const SizedBox(
          width: 300,
          child: SafeSegmentedProgress(total: 5, done: 2, current: 2),
        ),
      );

      final List<Color?> colors = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(SafeSegmentedProgress),
              matching: find.byType(Container),
            ),
          )
          .map((c) => (c.decoration as BoxDecoration?)?.color)
          .toList();
      const AppPalette p = AppPalette.light;
      expect(colors, [
        p.primary,
        p.primary,
        p.primary.withValues(alpha: 0.35),
        p.surfaceStrong,
        p.surfaceStrong,
      ]);
    });
  });
}
