import 'package:click_seguro_app/core/widgets/safe_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'initialValue atualiza sem apagar seleção/composição ao digitar',
    (tester) async {
      var value = 'Ana';
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: SafeTextField(
                initialValue: value,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pump();

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'Ana M',
          selection: TextSelection.collapsed(offset: 5),
          composing: TextRange(start: 4, end: 5),
        ),
      );
      await tester.pump();

      final valueAfterTyping = tester
          .widget<EditableText>(find.byType(EditableText))
          .controller
          .value;
      expect(value, 'Ana M');
      expect(
        valueAfterTyping.selection,
        const TextSelection.collapsed(offset: 5),
      );
      expect(valueAfterTyping.composing, const TextRange(start: 4, end: 5));
    },
  );

  testWidgets('troca controller externo por interno sem perder o texto', (
    tester,
  ) async {
    final external = TextEditingController.fromValue(
      const TextEditingValue(
        text: 'Ana',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    var useExternal = true;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Column(
              children: [
                SafeTextField(
                  controller: useExternal ? external : null,
                  initialValue: 'Ana',
                ),
                TextButton(
                  onPressed: () => setState(() => useExternal = false),
                  child: const Text('Trocar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Trocar'));
    await tester.pump();

    final value = tester
        .widget<EditableText>(find.byType(EditableText))
        .controller
        .value;
    expect(value.text, 'Ana');
    expect(value.selection, const TextSelection.collapsed(offset: 2));
    external.dispose();
  });
}
