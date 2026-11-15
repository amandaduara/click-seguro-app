import 'dart:ui' show Tristate;

import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/widgets/safe_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'component_test_app.dart';

void main() {
  BoxDecoration box(WidgetTester tester) =>
      tester.widget<Ink>(find.byType(Ink)).decoration! as BoxDecoration;

  testWidgets('não selecionado: creme, texto tinta, 48 de altura (RNF-003)', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      SafeChip(label: 'Pix', selected: false, onTap: () {}),
    );

    expect(box(tester).color, AppPalette.light.surface);
    expect(
      tester.widget<Text>(find.text('Pix')).style?.color,
      AppPalette.light.textForeground,
    );
    expect(
      tester.getSize(find.byType(SafeChip)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('selecionado: invertido em tinta, com semântica', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    int taps = 0;
    await pumpComponent(
      tester,
      SafeChip(label: 'Todas', selected: true, onTap: () => taps++),
    );

    expect(box(tester).color, AppPalette.light.secondary);
    expect(
      tester.widget<Text>(find.text('Todas')).style?.color,
      AppPalette.light.textPrimaryForeground,
    );
    final SemanticsData data = tester
        .getSemantics(find.byType(SafeChip))
        .getSemanticsData();
    expect(data.label, 'Todas');
    expect(data.flagsCollection.isSelected, Tristate.isTrue);
    expect(data.flagsCollection.isButton, isTrue);

    await tester.tap(find.byType(SafeChip));
    expect(taps, 1);

    // O leitor de tela também toca no chip.
    final SemanticsNode node = tester.getSemantics(find.byType(SafeChip));
    expect(
      node,
      isSemantics(isButton: true, isEnabled: true, hasTapAction: true),
    );
    node.owner!.performAction(node.id, SemanticsAction.tap);
    expect(taps, 2);
    handle.dispose();
  });

  testWidgets('sem onTap: desativado e sem ação para o leitor', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pumpComponent(
      tester,
      const SafeChip(label: 'Todas', selected: false),
    );

    expect(
      tester.getSemantics(find.byType(SafeChip)),
      isSemantics(isButton: true, isEnabled: false, hasTapAction: false),
    );
    handle.dispose();
  });
}
