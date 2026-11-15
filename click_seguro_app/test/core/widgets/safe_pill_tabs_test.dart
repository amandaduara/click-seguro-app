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

  testWidgets('cada aba tem alvo de toque de pelo menos 48 (RNF-003)', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      SizedBox(
        width: 300,
        child: SafePillTabs(
          tabs: const ['Oficiais', 'Meus contatos'],
          selectedIndex: 0,
          onChanged: (_) {},
        ),
      ),
    );

    final Finder tabs = find.descendant(
      of: find.byType(SafePillTabs),
      matching: find.byType(GestureDetector),
    );
    expect(tabs, findsNWidgets(2));
    for (int i = 0; i < 2; i++) {
      final Size size = tester.getSize(tabs.at(i));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    }
  });

  // Validação da usuária (specs/024): ao trocar, as duas opções piscavam
  // porque cada uma animava o próprio fundo. Agora um único indicador
  // desliza da aba antiga para a nova.
  testWidgets('a troca move um só indicador, sem fundo nas abas', (
    tester,
  ) async {
    final ValueNotifier<int> selected = ValueNotifier(0);
    addTearDown(selected.dispose);
    await pumpComponent(
      tester,
      SizedBox(
        width: 300,
        child: ValueListenableBuilder<int>(
          valueListenable: selected,
          builder: (_, index, _) => SafePillTabs(
            tabs: const ['Conversar', 'Verificar'],
            selectedIndex: index,
            onChanged: (value) => selected.value = value,
          ),
        ),
      ),
    );
    // O indicador é a única caixa que ocupa a fração de uma aba.
    final Finder indicator = find.descendant(
      of: find.byType(SafePillTabs),
      matching: find.byType(FractionallySizedBox),
    );
    expect(indicator, findsOneWidget);
    final double start = tester.getCenter(indicator).dx;
    expect(start, closeTo(tester.getCenter(find.text('Conversar')).dx, 1));

    await tester.tap(find.text('Verificar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    expect(indicator, findsOneWidget);
    final double midway = tester.getCenter(indicator).dx;
    expect(midway, greaterThan(start));

    await tester.pumpAndSettle();
    expect(
      tester.getCenter(indicator).dx,
      closeTo(tester.getCenter(find.text('Verificar')).dx, 1),
    );
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
