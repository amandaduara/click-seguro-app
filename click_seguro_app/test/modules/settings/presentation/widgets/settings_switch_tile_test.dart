import 'dart:ui' show Tristate;

import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_switch_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  late List<bool> changes;

  setUp(() => changes = []);

  Future<void> pumpTile(
    WidgetTester tester, {
    bool value = false,
    bool enabled = true,
    ThemeData? theme,
  }) => pumpLocalized(
    tester,
    theme: theme,
    child: Scaffold(
      body: SettingsSwitchTile(
        icon: LucideIcons.contrast,
        title: 'Alto contraste',
        subtitle: 'Cores mais fortes',
        value: value,
        onChanged: enabled ? changes.add : null,
      ),
    ),
  );

  testWidgets('título, subtítulo e a chave com o valor', (tester) async {
    await pumpTile(tester, value: true);

    expect(find.text('Alto contraste'), findsOneWidget);
    expect(find.text('Cores mais fortes'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('tocar na linha ou na chave inverte o valor', (tester) async {
    await pumpTile(tester);

    await tester.tap(find.text('Alto contraste'));
    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(changes, [true, true]);
  });

  testWidgets('sem onChanged: chave desabilitada e toque sem efeito', (
    tester,
  ) async {
    await pumpTile(tester, enabled: false);

    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    await tester.tap(find.text('Alto contraste'));
    await tester.pump();

    expect(changes, isEmpty);
  });

  testWidgets('anuncia ligado/desligado e mede 64+', (tester) async {
    await pumpTile(tester, value: true);

    expect(
      tester
          .getSemantics(find.text('Alto contraste'))
          .getSemanticsData()
          .flagsCollection
          .isToggled,
      Tristate.isTrue,
    );
    expect(
      tester.getSize(find.byType(SettingsSwitchTile)).height,
      greaterThanOrEqualTo(64),
    );
  });

  group('cores da paleta (nada de verde)', () {
    for (final (name, theme, palette) in [
      ('padrão', AppTheme.lightTheme, AppPalette.light),
      ('alto contraste', AppTheme.highContrastTheme, AppPalette.highContrast),
    ]) {
      testWidgets('$name: ligada na cor da marca', (tester) async {
        await pumpTile(tester, value: true, theme: theme);
        final Switch toggle = tester.widget<Switch>(find.byType(Switch));

        expect(toggle.activeTrackColor, palette.primary);
        expect(toggle.activeTrackColor, isNot(palette.success));
        expect(toggle.activeThumbColor, palette.card);
        expect(
          toggle.trackOutlineColor!.resolve({WidgetState.selected}),
          palette.primary,
        );
      });

      testWidgets('$name: desligada creme com contorno', (tester) async {
        await pumpTile(tester, theme: theme);
        final Switch toggle = tester.widget<Switch>(find.byType(Switch));

        expect(toggle.inactiveTrackColor, palette.surfaceStrong);
        expect(toggle.inactiveThumbColor, palette.textMutedForeground);
        expect(toggle.trackOutlineColor!.resolve({}), palette.inputBorder);
      });
    }

    test('alto contraste: trilho ligado contrasta 4,5:1 com a bolinha', () {
      const AppPalette hc = AppPalette.highContrast;
      double luminance(Color c) => c.computeLuminance();
      final double l1 = luminance(hc.card);
      final double l2 = luminance(hc.primary);
      final double ratio =
          (l1 > l2 ? l1 + 0.05 : l2 + 0.05) / (l1 > l2 ? l2 + 0.05 : l1 + 0.05);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });
}
