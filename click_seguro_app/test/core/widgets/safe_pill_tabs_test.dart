import 'dart:ui' show Tristate;

import 'package:click_seguro_app/core/widgets/safe_pill_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'component_test_app.dart';

void main() {
  testWidgets('mostra as abas, marca a atual e avisa a troca', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final List<int> changes = [];
    await pumpComponent(
      tester,
      SafePillTabs(
        tabs: const ['Oficiais', 'Meus contatos'],
        selectedIndex: 0,
        onChanged: changes.add,
      ),
    );

    expect(find.text('Oficiais'), findsOneWidget);
    expect(find.text('Meus contatos'), findsOneWidget);
    final SemanticsData selected = tester
        .getSemantics(find.text('Oficiais'))
        .getSemanticsData();
    expect(selected.flagsCollection.isSelected, Tristate.isTrue);
    final SemanticsData other = tester
        .getSemantics(find.text('Meus contatos'))
        .getSemanticsData();
    expect(other.flagsCollection.isSelected, Tristate.isFalse);
    expect(
      tester.getSize(find.byType(SafePillTabs)).height,
      greaterThanOrEqualTo(56),
    );

    await tester.tap(find.text('Meus contatos'));
    expect(changes, [1]);
    handle.dispose();
  });

  testWidgets('com fonte 2x em 320 px não estoura', (tester) async {
    await pumpComponent(
      tester,
      SizedBox(
        width: 288,
        child: SafePillTabs(
          tabs: const ['Conversar', 'Verificar', 'Histórico'],
          selectedIndex: 1,
          onChanged: (_) {},
        ),
      ),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
  });
}
