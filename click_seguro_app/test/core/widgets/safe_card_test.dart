import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<SemanticsData> semanticsOf(
    WidgetTester tester, {
    required bool interactive,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeCard(
            interactive: interactive,
            onTap: interactive ? () {} : null,
            child: const Text('Golpe do Pix'),
          ),
        ),
      ),
    );
    return tester.getSemantics(find.text('Golpe do Pix')).getSemanticsData();
  }

  testWidgets('cartão tocável é anunciado como botão (specs/022 FR-007)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    final data = await semanticsOf(tester, interactive: true);

    expect(data.flagsCollection.isButton, isTrue);
    expect(data.label, 'Golpe do Pix');
    handle.dispose();
  });

  testWidgets('cartão só de leitura não é botão', (tester) async {
    final handle = tester.ensureSemantics();

    final data = await semanticsOf(tester, interactive: false);

    expect(data.flagsCollection.isButton, isFalse);
    handle.dispose();
  });
}
