import 'dart:ui' show Tristate;

import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Color?> labelColor(WidgetTester tester, SafeButtonTone tone) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeButton(label: 'Botão', tone: tone, onPressed: () {}),
        ),
      ),
    );
    return tester.widget<Text>(find.text('Botão')).style?.color;
  }

  testWidgets('secondary usa texto claro sobre o azul-escuro', (tester) async {
    expect(
      await labelColor(tester, SafeButtonTone.secondary),
      AppColors.textPrimaryForeground,
    );
  });

  testWidgets('primary usa texto claro', (tester) async {
    expect(
      await labelColor(tester, SafeButtonTone.primary),
      AppColors.textPrimaryForeground,
    );
  });

  testWidgets('no alto contraste, usa o vermelho-escuro do tema (RF-039)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.highContrastTheme,
        home: Scaffold(
          body: SafeButton(label: 'Botão', onPressed: () {}),
        ),
      ),
    );

    final Iterable<Color?> backgrounds = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(SafeButton),
            matching: find.byType(Container),
          ),
        )
        .map((container) => (container.decoration as BoxDecoration?)?.color);
    expect(backgrounds, contains(AppPalette.highContrast.primary));
  });

  group('leitor de tela (specs/022 FR-007)', () {
    Future<void> pumpButton(
      WidgetTester tester, {
      bool disabled = false,
      bool loading = false,
    }) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeButton(
            label: 'Entrar',
            disabled: disabled,
            loading: loading,
            onPressed: () {},
          ),
        ),
      ),
    );

    testWidgets('é anunciado como botão habilitado, com o rótulo', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpButton(tester);

      expect(
        tester.getSemantics(find.byType(SafeButton)),
        matchesSemantics(
          label: 'Entrar',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('desabilitado ou carregando: botão desabilitado', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final (disabled, loading) in [(true, false), (false, true)]) {
        await pumpButton(tester, disabled: disabled, loading: loading);

        final data = tester
            .getSemantics(find.byType(SafeButton))
            .getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      }
      handle.dispose();
    });
  });
}
