import 'package:click_seguro_app/core/widgets/safe_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'component_test_app.dart';

/// Moldura da folha inferior: alça e conteúdo (contrato de
/// specs/024-redesign-visual).
void main() {
  testWidgets('mostra a alça e o conteúdo', (tester) async {
    await pumpComponent(tester, const SafeSheet(child: Text('Conteúdo')));

    final Finder handle = find.descendant(
      of: find.byType(SafeSheet),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.maxWidth == 44 &&
            widget.constraints?.maxHeight == 5,
      ),
    );
    expect(handle, findsOneWidget);
    expect(find.text('Conteúdo'), findsOneWidget);
  });
}
