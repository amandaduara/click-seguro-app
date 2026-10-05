import 'package:click_seguro_app/core/widgets/coming_soon_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/localized_app.dart';

void main() {
  testWidgets('mostra o título como cabeçalho e "Em breve"', (tester) async {
    final semantics = tester.ensureSemantics();

    await pumpLocalized(
      tester,
      child: const Scaffold(body: ComingSoonView(title: 'Atividades')),
    );

    expect(find.text('Atividades'), findsOneWidget);
    expect(find.text('Em breve'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Atividades')),
      matchesSemantics(label: 'Atividades', isHeader: true),
    );
    semantics.dispose();
  });
}
