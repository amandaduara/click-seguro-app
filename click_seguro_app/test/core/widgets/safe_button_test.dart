import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Botões do redesign 2.0 (FR-006; contrato de specs/023-redesign-visual).
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget button, {
    ThemeData? theme,
    bool disableAnimations = false,
    double textScale = 1,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: disableAnimations,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: Center(child: button)),
      ),
    ),
  );

  BoxDecoration decoration(WidgetTester tester) =>
      tester
              .widget<Container>(
                find
                    .descendant(
                      of: find.byType(SafeButton),
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .decoration!
          as BoxDecoration;

  Color? labelColor(WidgetTester tester) =>
      tester.widget<Text>(find.text('Botão')).style?.color;

  group('tons', () {
    const AppPalette p = AppPalette.light;

    testWidgets('primário: coral com texto branco', (tester) async {
      await pump(tester, SafeButton(label: 'Botão', onPressed: () {}));

      expect(decoration(tester).color, p.primary);
      expect(labelColor(tester), p.textPrimaryForeground);
    });

    testWidgets('secundário: creme com texto tinta', (tester) async {
      await pump(
        tester,
        SafeButton(
          label: 'Botão',
          tone: SafeButtonTone.secondary,
          onPressed: () {},
        ),
      );

      expect(decoration(tester).color, p.surfaceStrong);
      expect(labelColor(tester), p.textForeground);
    });

    testWidgets('contorno (ghost): branco com borda tinta', (tester) async {
      await pump(
        tester,
        SafeButton(
          label: 'Botão',
          tone: SafeButtonTone.ghost,
          onPressed: () {},
        ),
      );

      final BoxDecoration box = decoration(tester);
      expect(box.color, p.card);
      expect((box.border! as Border).top.color, p.textForeground);
    });

    testWidgets('link: sem fundo, texto sublinhado', (tester) async {
      await pump(
        tester,
        SafeButton(label: 'Botão', tone: SafeButtonTone.link, onPressed: () {}),
      );

      expect(decoration(tester).color, Colors.transparent);
      expect(
        tester.widget<Text>(find.text('Botão')).style?.decoration,
        TextDecoration.underline,
      );
    });

    testWidgets('alto contraste usa o vermelho-escuro do tema (RF-039)', (
      tester,
    ) async {
      await pump(
        tester,
        SafeButton(label: 'Botão', onPressed: () {}),
        theme: AppTheme.highContrastTheme,
      );

      expect(decoration(tester).color, AppPalette.highContrast.primary);
    });
  });

  group('tamanhos', () {
    testWidgets('large tem pelo menos 60 de altura', (tester) async {
      await pump(tester, SafeButton(label: 'Botão', onPressed: () {}));

      expect(
        tester.getSize(find.byType(SafeButton)).height,
        greaterThanOrEqualTo(60),
      );
    });

    testWidgets('compact tem pelo menos 48 de altura (RNF-003)', (
      tester,
    ) async {
      await pump(
        tester,
        SafeButton(
          label: 'Botão',
          size: SafeButtonSize.compact,
          onPressed: () {},
        ),
      );

      expect(
        tester.getSize(find.byType(SafeButton)).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('texto longo com fonte 2x cresce sem estourar', (tester) async {
      await pump(
        tester,
        SizedBox(
          width: 300,
          child: SafeButton(
            label: 'Continuar sem login e ver as notícias de hoje',
            onPressed: () {},
          ),
        ),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(SafeButton)).height, greaterThan(60));
    });
  });

  group('toque', () {
    testWidgets('chama onPressed e encolhe ao pressionar', (tester) async {
      int taps = 0;
      await pump(tester, SafeButton(label: 'Botão', onPressed: () => taps++));

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(SafeButton)),
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
        SafeButton(label: 'Botão', onPressed: () {}),
        disableAnimations: true,
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(SafeButton)),
      );
      await tester.pump();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await gesture.up();
    });

    testWidgets('desativado não chama onPressed', (tester) async {
      int taps = 0;
      await pump(
        tester,
        SafeButton(label: 'Botão', disabled: true, onPressed: () => taps++),
      );

      await tester.tap(find.byType(SafeButton));
      expect(taps, 0);
    });
  });

  testWidgets('carregando mantém o rótulo para o leitor de tela', (
    tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pump(
      tester,
      SafeButton(label: 'Botão', loading: true, onPressed: () {}),
    );

    expect(find.bySemanticsLabel('Botão'), findsOneWidget);
    handle.dispose();
  });
}
