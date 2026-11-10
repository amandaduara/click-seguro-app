import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cartões do redesign 2.0 (FR-004; contrato de specs/023-redesign-visual).
void main() {
  Future<void> pump(
    WidgetTester tester,
    SafeCard card, {
    ThemeData? theme,
    bool disableAnimations = false,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: Center(child: card)),
      ),
    ),
  );

  BoxDecoration box(WidgetTester tester) =>
      tester
              .widget<AnimatedContainer>(
                find.descendant(
                  of: find.byType(SafeCard),
                  matching: find.byType(AnimatedContainer),
                ),
              )
              .decoration!
          as BoxDecoration;

  testWidgets('branco, canto 20 e a sombra única', (tester) async {
    await pump(tester, const SafeCard(child: Text('Cartão')));

    expect(box(tester).color, AppPalette.light.card);
    expect(box(tester).borderRadius, BorderRadius.circular(20));
    expect(box(tester).boxShadow, AppPalette.light.shadow);
  });

  testWidgets('plano: creme, sem sombra', (tester) async {
    await pump(
      tester,
      const SafeCard(elevation: SafeCardElevation.flat, child: Text('Cartão')),
    );

    expect(box(tester).color, AppPalette.light.surface);
    expect(box(tester).boxShadow, isNull);
  });

  testWidgets('alto contraste: sem sombra, com borda', (tester) async {
    await pump(
      tester,
      const SafeCard(child: Text('Cartão')),
      theme: AppTheme.highContrastTheme,
    );

    expect(box(tester).boxShadow, isEmpty);
    expect(
      (box(tester).border! as Border).top.color,
      AppPalette.highContrast.border,
    );
  });

  testWidgets('tocável: chama onTap e encolhe para 98%', (tester) async {
    int taps = 0;
    await pump(
      tester,
      SafeCard(
        interactive: true,
        onTap: () => taps++,
        child: const Text('Cartão'),
      ),
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('Cartão')),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      0.98,
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('com reduzir animações, não encolhe (FR-021)', (tester) async {
    await pump(
      tester,
      SafeCard(interactive: true, onTap: () {}, child: const Text('Cartão')),
      disableAnimations: true,
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('Cartão')),
    );
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await gesture.up();
  });
}
