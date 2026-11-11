import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/widgets/safe_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'component_test_app.dart';

void main() {
  BoxDecoration box(WidgetTester tester) =>
      tester.widget<Ink>(find.byType(Ink)).decoration! as BoxDecoration;

  testWidgets('redondo, creme, alvo de 48 e rótulo de leitura (FR-005)', (
    tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    int taps = 0;
    await pumpComponent(
      tester,
      SafeIconButton(
        icon: LucideIcons.bell,
        semanticLabel: 'Alertas',
        onPressed: () => taps++,
      ),
    );

    expect(tester.getSize(find.byType(SafeIconButton)), const Size(48, 48));
    expect(find.bySemanticsLabel('Alertas'), findsOneWidget);
    expect(box(tester).color, AppPalette.light.surface);

    await tester.tap(find.byType(SafeIconButton));
    expect(taps, 1);

    // O leitor de tela também toca no botão.
    expect(
      tester.getSemantics(find.bySemanticsLabel('Alertas')),
      isSemantics(isButton: true, isEnabled: true, hasTapAction: true),
    );
    final SemanticsNode node = tester.getSemantics(
      find.bySemanticsLabel('Alertas'),
    );
    node.owner!.performAction(node.id, SemanticsAction.tap);
    expect(taps, 2);
    handle.dispose();
  });

  testWidgets('sobre imagem: branco com a sombra única, tamanho 56', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      SafeIconButton(
        icon: LucideIcons.share2,
        semanticLabel: 'Compartilhar',
        onImage: true,
        size: 56,
        onPressed: () {},
      ),
    );

    expect(tester.getSize(find.byType(SafeIconButton)), const Size(56, 56));
    expect(box(tester).color, AppPalette.light.card);
    expect(box(tester).boxShadow, AppPalette.light.shadow);
  });
}
