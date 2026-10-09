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
}
