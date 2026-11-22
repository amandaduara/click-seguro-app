import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  void usePhone(WidgetTester tester, {double textScale = 1}) {
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<void> pumpScaffold(WidgetTester tester, String title) => pumpLocalized(
    tester,
    child: SettingsScaffold(title: title, children: const [Text('conteúdo')]),
  );

  testWidgets('o título fica na mesma linha, logo à direita do voltar', (
    tester,
  ) async {
    usePhone(tester);
    await pumpScaffold(tester, 'Privacidade');

    final Rect back = tester.getRect(find.byKey(SettingsBackButton.buttonKey));
    final Rect title = tester.getRect(find.text('Privacidade'));

    expect(title.left, greaterThan(back.right));
    expect(title.left - back.right, lessThanOrEqualTo(24));
    expect(title.center.dy, moreOrLessEquals(back.center.dy, epsilon: 2));
    // O conteúdo começa abaixo da linha do topo.
    expect(
      tester.getTopLeft(find.text('conteúdo')).dy,
      greaterThan(back.bottom),
    );
  });

  testWidgets('o título é cabeçalho para o leitor de tela', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpScaffold(tester, 'Privacidade');

    expect(
      tester.getSemantics(find.text('Privacidade')),
      matchesSemantics(label: 'Privacidade', isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('letra 2×: o título longo quebra linha ao lado do voltar, '
      'sem estouro', (tester) async {
    usePhone(tester, textScale: 2);
    await pumpScaffold(tester, 'Sobre o Click Seguro');

    expect(tester.takeException(), isNull);
    final Rect back = tester.getRect(find.byKey(SettingsBackButton.buttonKey));
    final Rect title = tester.getRect(find.text('Sobre o Click Seguro'));
    expect(title.left, greaterThan(back.right));
    expect(title.right, lessThanOrEqualTo(360));
    // Mais de uma linha: bem mais alto que o botão.
    expect(title.height, greaterThan(back.height));
  });
}
