import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/modules/shell/presentation/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  Future<List<int>> pumpNav(WidgetTester tester) async {
    final selected = <int>[];
    await pumpLocalized(
      tester,
      child: Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: AppBottomNav(
          currentIndex: 0,
          onSelected: selected.add,
        ),
      ),
    );
    return selected;
  }

  testWidgets('tocar numa aba avisa qual foi', (tester) async {
    final selected = await pumpNav(tester);

    await tester.tap(find.bySemanticsLabel('Perfil'));

    expect(selected, [AppTab.profile.index]);
  });

  testWidgets('só ícones; o nome da aba fica no leitor de tela', (
    tester,
  ) async {
    await pumpNav(tester);

    for (final String label in [
      'Início',
      'Atividades',
      'Notícias',
      'Ajuda',
      'Perfil',
    ]) {
      expect(find.text(label), findsNothing);
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
  });

  testWidgets('a aba ativa fica num círculo coral de 44 com o ícone branco', (
    tester,
  ) async {
    await pumpNav(tester);
    final BuildContext context = tester.element(find.byType(AppBottomNav));
    final AppPalette colors = context.colors;

    final Finder circle = find.ancestor(
      of: find.byIcon(AppTab.home.icon),
      matching: find.byType(AnimatedContainer),
    );
    final BoxDecoration decoration =
        tester.widget<AnimatedContainer>(circle).decoration! as BoxDecoration;
    expect(decoration.color, colors.primary);
    expect(decoration.shape, BoxShape.circle);
    expect(tester.getSize(circle), const Size(44, 44));
    expect(
      tester.widget<Icon>(find.byIcon(AppTab.home.icon)).color,
      colors.textPrimaryForeground,
    );
  });

  testWidgets('cada aba tem alvo de 48 ou mais', (tester) async {
    await pumpNav(tester);

    for (final AppTab tab in AppTab.values) {
      final Size size = tester.getSize(
        find.ancestor(
          of: find.byIcon(tab.icon),
          matching: find.byType(InkResponse),
        ),
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('a aba ativa troca de cor com animação curta (FR-025)', (
    tester,
  ) async {
    final ValueNotifier<int> current = ValueNotifier(0);
    addTearDown(current.dispose);
    await pumpLocalized(
      tester,
      child: Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: ValueListenableBuilder<int>(
          valueListenable: current,
          builder: (_, index, _) =>
              AppBottomNav(currentIndex: index, onSelected: (_) {}),
        ),
      ),
    );
    Color? iconColor(IconData icon) =>
        tester.widget<Icon>(find.byIcon(icon)).color;
    final Color? muted = iconColor(AppTab.activities.icon);
    final Color? active = iconColor(AppTab.home.icon);
    // Sem desfoque: o conteúdo não passa por trás da barra (revisão do PR #28).
    expect(find.byType(BackdropFilter), findsNothing);

    current.value = AppTab.activities.index;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final Color? midway = iconColor(AppTab.activities.icon);
    expect(midway, isNot(muted));
    expect(midway, isNot(active));

    await tester.pumpAndSettle();
    expect(iconColor(AppTab.activities.icon), active);
    expect(iconColor(AppTab.home.icon), muted);
  });
}
