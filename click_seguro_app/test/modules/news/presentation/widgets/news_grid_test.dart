import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_news_repository.dart';

void main() {
  /// Cada cartão é uma caixa com a altura da capa e o id como texto.
  Future<void> pump(
    WidgetTester tester,
    List<NewsItemEntity> items, {
    double textScale = 1,
    double height = 2000,
  }) async {
    tester.view.physicalSize = Size(400, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(400, height),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: CustomScrollView(
              slivers: [
                NewsGrid(
                  items: items,
                  itemBuilder: (item, coverHeight) => SizedBox(
                    key: ValueKey(item.id),
                    height: coverHeight,
                    child: Text(item.id),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Rect rectOf(WidgetTester tester, String id) =>
      tester.getRect(find.byKey(ValueKey(id)));

  testWidgets('pares à esquerda, ímpares à direita, na ordem da API', (
    tester,
  ) async {
    await pump(tester, newsItems(5));

    final List<Rect> rects = [
      for (int i = 1; i <= 5; i++) rectOf(tester, 'n$i'),
    ];
    // Duas colunas iguais com 14 entre elas.
    expect(rects[0].width, (400 - NewsGrid.columnGap) / 2);
    expect(rects[1].left - rects[0].right, NewsGrid.columnGap);
    for (final i in [2, 4]) {
      expect(rects[i].left, rects[0].left);
      expect(rects[i].top, greaterThan(rects[i - 2].top));
    }
    expect(rects[3].left, rects[1].left);
    expect(rects[3].top, greaterThan(rects[1].top));
    expect(rects[0].top, rects[1].top);
  });

  testWidgets('alturas determinísticas pela posição na lista', (tester) async {
    await pump(tester, newsItems(6));

    for (int i = 0; i < 6; i++) {
      expect(
        rectOf(tester, 'n${i + 1}').height,
        NewsGrid.coverHeightAt(i),
        reason: 'índice $i',
      );
    }
    expect(NewsGrid.coverHeightAt(4), NewsGrid.coverHeightAt(0));
  });

  testWidgets('letra acima de 1,3: uma coluna, na ordem e com capa maior', (
    tester,
  ) async {
    await pump(tester, newsItems(3), textScale: 1.5);

    final List<Rect> rects = [
      for (int i = 1; i <= 3; i++) rectOf(tester, 'n$i'),
    ];
    for (final (index, rect) in rects.indexed) {
      expect(rect.width, 400);
      expect(
        rect.height,
        NewsGrid.coverHeightAt(index) + NewsGrid.singleColumnExtra,
      );
    }
    expect(rects[0].top, lessThan(rects[1].top));
    expect(rects[1].top, lessThan(rects[2].top));
  });

  testWidgets('letra em 1,3: ainda duas colunas', (tester) async {
    await pump(tester, newsItems(2), textScale: 1.3);

    expect(rectOf(tester, 'n1').top, rectOf(tester, 'n2').top);
  });

  testWidgets('preguiçosa: só monta os cartões perto da tela', (tester) async {
    await pump(tester, newsItems(200), height: 600);

    expect(find.text('n1'), findsOneWidget);
    expect(find.text('n2'), findsOneWidget);
    expect(find.text('n200'), findsNothing);
    expect(find.text('n199'), findsNothing);
  });
}
