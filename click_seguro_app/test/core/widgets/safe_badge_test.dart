import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/widgets/safe_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/localized_app.dart';

/// Selos do redesign 2.0: fundo "suave" e texto forte da mesma família, com
/// contraste AA (FR-001, FR-007; contrato de specs/023-redesign-visual).
void main() {
  Future<void> pumpBadge(WidgetTester tester, SafeBadgeTone tone) =>
      pumpLocalized(
        tester,
        child: Scaffold(
          body: Center(
            child: SafeBadge(tone: tone, child: const Text('Não iniciado')),
          ),
        ),
      );

  BoxDecoration box(WidgetTester tester) {
    final Container container = tester.widget(
      find.descendant(
        of: find.byType(SafeBadge),
        matching: find.byType(Container),
      ),
    );
    return container.decoration! as BoxDecoration;
  }

  TextStyle textStyle(WidgetTester tester) =>
      DefaultTextStyle.of(tester.element(find.text('Não iniciado'))).style;

  const AppPalette p = AppPalette.light;
  final Map<SafeBadgeTone, (Color, Color)> expected = {
    SafeBadgeTone.primary: (p.primarySoft, p.primaryPressed),
    SafeBadgeTone.secondary: (p.surfaceStrong, p.textForeground),
    SafeBadgeTone.success: (p.successSoft, p.success),
    SafeBadgeTone.warning: (p.warningSoft, p.warning),
    SafeBadgeTone.destructive: (p.primarySoft, p.destructive),
    SafeBadgeTone.neutral: (p.surfaceStrong, p.textMutedForeground),
    SafeBadgeTone.onImage: (p.card, p.textForeground),
  };

  for (final MapEntry<SafeBadgeTone, (Color, Color)> entry
      in expected.entries) {
    testWidgets('${entry.key.name}: fundo e texto do tom', (tester) async {
      await pumpBadge(tester, entry.key);

      expect(box(tester).color, entry.value.$1);
      expect(textStyle(tester).color, entry.value.$2);
    });
  }

  testWidgets('texto de 15 em negrito, o mínimo do app (FR-003)', (
    tester,
  ) async {
    await pumpBadge(tester, SafeBadgeTone.success);

    expect(textStyle(tester).fontSize, 15);
    expect(textStyle(tester).fontWeight, FontWeight.w700);
  });

  testWidgets('sobre imagem leva a sombra única', (tester) async {
    await pumpBadge(tester, SafeBadgeTone.onImage);

    expect(box(tester).boxShadow, p.shadow);
  });
}
