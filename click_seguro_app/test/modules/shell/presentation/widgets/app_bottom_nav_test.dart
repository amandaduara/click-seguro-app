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

  /// O círculo de 64 dp do botão central de Reels.
  Finder centerCircle() => find.descendant(
    of: find.byType(AppBottomNav),
    matching: find.byWidgetPredicate(
      (w) => w is Container && w.constraints?.maxWidth == 64,
    ),
  );

  testWidgets('tocar no topo do círculo central abre os Reels (FR-006)', (
    tester,
  ) async {
    final selected = await pumpNav(tester);
    final Rect circle = tester.getRect(centerCircle());

    // 4 dp abaixo do topo do círculo: a parte que sobe acima da barra.
    await tester.tapAt(Offset(circle.center.dx, circle.top + 4));

    expect(selected, [AppTab.news.index]);
  });

  testWidgets('as outras abas continuam respondendo ao lado do círculo', (
    tester,
  ) async {
    final selected = await pumpNav(tester);

    await tester.tap(find.text('Perfil'));

    expect(selected, [AppTab.profile.index]);
  });
}
