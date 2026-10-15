import 'dart:ui' show CheckedState;

import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_option_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  late int? chosen;

  setUp(() => chosen = null);

  Future<void> pumpGroup(WidgetTester tester, {int selected = 2}) =>
      pumpLocalized(
        tester,
        child: Scaffold(
          body: RadioGroup<int>(
            groupValue: selected,
            onChanged: (value) => chosen = value,
            child: const Column(
              children: [
                SettingsOptionTile<int>(
                  value: 1,
                  title: 'Um',
                  trailingText: '1%',
                ),
                SettingsOptionTile<int>(value: 2, title: 'Dois'),
                SettingsOptionTile<int>(value: 3, title: 'Três'),
              ],
            ),
          ),
        ),
      );

  testWidgets('título, texto à direita e a opção do grupo marcada', (
    tester,
  ) async {
    await pumpGroup(tester);

    expect(find.text('Um'), findsOneWidget);
    expect(find.text('1%'), findsOneWidget);
    final radios = tester.widgetList<Radio<int>>(find.byType(Radio<int>));
    expect([for (final radio in radios) radio.value], [1, 2, 3]);
    expect(
      tester
          .getSemantics(find.text('Dois'))
          .getSemanticsData()
          .flagsCollection
          .isChecked,
      CheckedState.isTrue,
    );
    expect(
      tester
          .getSemantics(find.text('Um'))
          .getSemanticsData()
          .flagsCollection
          .isChecked,
      CheckedState.isFalse,
    );
  });

  testWidgets('tocar no título escolhe a opção', (tester) async {
    await pumpGroup(tester);

    await tester.tap(find.text('Três'));
    await tester.pump();

    expect(chosen, 3);
  });

  testWidgets('linha lida como uma opção só, com nome e texto à direita', (
    tester,
  ) async {
    await pumpGroup(tester);

    final SemanticsNode node = tester.getSemantics(find.text('Um'));
    expect(node.label, contains('Um'));
    expect(node.label, contains('1%'));
    expect(
      node.getSemanticsData().flagsCollection.isInMutuallyExclusiveGroup,
      isTrue,
    );
  });

  testWidgets('altura mínima de 64', (tester) async {
    await pumpGroup(tester);

    expect(
      tester.getSize(find.byType(SettingsOptionTile<int>).first).height,
      greaterThanOrEqualTo(64),
    );
  });
}
