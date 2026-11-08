import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/widgets/safe_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'component_test_app.dart';

/// Campo de texto do redesign 2.0: rótulo sempre acima, 60 de altura, foco
/// com borda tinta e erro com mensagem e ícone (FR-007).
void main() {
  const AppPalette p = AppPalette.light;

  BoxDecoration box(WidgetTester tester) =>
      tester
              .widget<AnimatedContainer>(
                find.descendant(
                  of: find.byType(SafeTextField),
                  matching: find.byType(AnimatedContainer),
                ),
              )
              .decoration!
          as BoxDecoration;

  testWidgets('rótulo acima do campo e 60 de altura', (tester) async {
    await pumpComponent(
      tester,
      const SafeTextField(label: 'E-mail', placeholder: 'seu@email.com'),
    );

    final Offset label = tester.getTopLeft(find.text('E-mail'));
    final Offset field = tester.getTopLeft(find.byType(AnimatedContainer));
    expect(label.dy, lessThan(field.dy));
    expect(
      tester.getSize(find.byType(AnimatedContainer)).height,
      greaterThanOrEqualTo(60),
    );
  });

  testWidgets('sem foco: borda do campo; com foco: tinta 2,5', (tester) async {
    await pumpComponent(tester, const SafeTextField(label: 'E-mail'));

    expect((box(tester).border! as Border).top.color, p.inputBorder);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final BorderSide side = (box(tester).border! as Border).top;
    expect(side.color, p.textForeground);
    expect(side.width, 2.5);
  });

  testWidgets('erro: borda e mensagem na cor de erro, com ícone', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const SafeTextField(label: 'E-mail', error: 'Digite um e-mail válido.'),
    );

    expect((box(tester).border! as Border).top.color, p.destructive);
    expect(
      tester.widget<Text>(find.text('Digite um e-mail válido.')).style?.color,
      p.destructive,
    );
    expect(find.byIcon(LucideIcons.circleAlert), findsOneWidget);
  });
}
