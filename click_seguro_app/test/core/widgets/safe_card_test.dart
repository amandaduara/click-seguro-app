import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

  double scale(WidgetTester tester) => tester
      .widget<ScaleTransition>(
        find.descendant(
          of: find.byType(SafeCard),
          matching: find.byType(ScaleTransition),
        ),
      )
      .scale
      .value;

  testWidgets('branco, borda, canto 20 e a sombra única', (tester) async {
    await pump(tester, const SafeCard(child: Text('Cartão')));

    expect(box(tester).color, AppPalette.light.card);
    expect(box(tester).borderRadius, BorderRadius.circular(20));
    expect((box(tester).border! as Border).top.color, AppPalette.light.border);
    expect((box(tester).border! as Border).top.width, 1);
    expect(box(tester).boxShadow, AppPalette.light.shadow);
  });

  test('decoration: a mesma caixa para quem desenha a própria', () {
    expect(
      SafeCard.decoration(AppPalette.light),
      BoxDecoration(
        color: AppPalette.light.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.light.border),
        boxShadow: AppPalette.light.shadow,
      ),
    );
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
    expect(scale(tester), 0.98);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(scale(tester), 1);
  });

  testWidgets('com reduzir animações, não anima a escala (FR-021)', (
    tester,
  ) async {
    await pump(
      tester,
      SafeCard(interactive: true, onTap: () {}, child: const Text('Cartão')),
      disableAnimations: true,
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('Cartão')),
    );
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    await gesture.up();
    await tester.pump();
    expect(scale(tester), 1);
  });

  group('leitor de tela (specs/022 FR-007)', () {
    Future<SemanticsData> semanticsOf(
      WidgetTester tester, {
      required bool interactive,
    }) async {
      await pump(
        tester,
        SafeCard(
          interactive: interactive,
          onTap: interactive ? () {} : null,
          child: const Text('Golpe do Pix'),
        ),
      );
      return tester.getSemantics(find.text('Golpe do Pix')).getSemanticsData();
    }

    testWidgets('cartão tocável é anunciado como botão', (tester) async {
      final handle = tester.ensureSemantics();

      final data = await semanticsOf(tester, interactive: true);

      expect(data.flagsCollection.isButton, isTrue);
      expect(data.label, 'Golpe do Pix');
      handle.dispose();
    });

    testWidgets('cartão só de leitura não é botão', (tester) async {
      final handle = tester.ensureSemantics();

      final data = await semanticsOf(tester, interactive: false);

      expect(data.flagsCollection.isButton, isFalse);
      handle.dispose();
    });
  });
}
