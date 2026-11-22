import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/localized_app.dart';

/// Linha das Configurações com um valor ao lado da seta ("Idioma  English >"):
/// o valor e a seta ficam encostados à direita, como nas outras linhas (erro
/// visto no aparelho: ficavam no meio).
void main() {
  Future<void> pumpTile(WidgetTester tester) => pumpLocalized(
    tester,
    child: Scaffold(
      body: SettingsTile(
        icon: LucideIcons.globe,
        title: 'Language',
        value: 'English',
        onTap: () {},
      ),
    ),
  );

  testWidgets('valor e seta encostados à direita', (tester) async {
    await pumpTile(tester);

    final Rect tile = tester.getRect(find.byType(SettingsTile));
    final Rect chevron = tester.getRect(find.byIcon(LucideIcons.chevronRight));
    final Rect value = tester.getRect(find.text('English'));

    // A seta fica no fim da linha (só a margem interna depois dela).
    expect(tile.right - chevron.right, lessThan(24));
    // O valor fica logo antes da seta.
    expect(chevron.left - value.right, lessThan(16));
  });

  testWidgets('com letra 2×, sem estouro', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpTile(tester);

    expect(tester.takeException(), isNull);
  });
}
