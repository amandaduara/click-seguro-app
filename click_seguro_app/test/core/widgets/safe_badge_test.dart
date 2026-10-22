import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/widgets/safe_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/localized_app.dart';

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

  Color background(WidgetTester tester) {
    final Container box = tester.widget(
      find.descendant(
        of: find.byType(SafeBadge),
        matching: find.byType(Container),
      ),
    );
    return (box.decoration! as BoxDecoration).color!;
  }

  Color textColor(WidgetTester tester) => DefaultTextStyle.of(
    tester.element(find.text('Não iniciado')),
  ).style.color!;

  testWidgets('neutro: texto legível, fundo a 10% da cor do texto', (
    tester,
  ) async {
    await pumpBadge(tester, SafeBadgeTone.neutral);

    expect(textColor(tester), AppPalette.light.textMutedForeground);
    expect(
      background(tester),
      AppPalette.light.textMutedForeground.withValues(alpha: 0.1),
    );
    expect(background(tester), isNot(textColor(tester)));
  });

  testWidgets('os outros tons seguem a mesma regra', (tester) async {
    await pumpBadge(tester, SafeBadgeTone.success);

    expect(textColor(tester), AppPalette.light.success);
    expect(background(tester), AppPalette.light.success.withValues(alpha: 0.1));
  });
}
