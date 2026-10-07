import 'package:click_seguro_app/modules/news/domain/entities/news_category_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/category_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';

void main() {
  const categories = [
    NewsCategoryEntity(id: '1', name: 'Phishing', slug: 'phishing'),
    NewsCategoryEntity(
      id: '2',
      name: 'Golpes bancários',
      slug: 'golpes-bancarios',
    ),
  ];

  Future<List<String?>> pumpBar(WidgetTester tester, {String? selected}) async {
    final selections = <String?>[];
    await pumpLocalized(
      tester,
      child: Scaffold(
        body: CategoryFilterBar(
          categories: categories,
          selectedSlug: selected,
          onSelected: selections.add,
        ),
      ),
    );
    return selections;
  }

  testWidgets('"Todas" e os nomes; "Todas" selecionado', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpBar(tester);

    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('Phishing'), findsOneWidget);
    expect(find.text('Golpes bancários'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Todas')),
      isSemantics(isSelected: true, isButton: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Phishing')),
      isSemantics(isSelected: false),
    );
    semantics.dispose();
  });

  testWidgets('tocar avisa o slug; "Todas" avisa null', (tester) async {
    final selections = await pumpBar(tester, selected: 'phishing');

    await tester.tap(find.text('Golpes bancários'));
    await tester.tap(find.text('Todas'));

    expect(selections, ['golpes-bancarios', null]);
  });

  testWidgets('chips com pelo menos 48 de altura e rolagem lateral', (
    tester,
  ) async {
    await pumpBar(tester);

    for (final label in ['Todas', 'Phishing']) {
      expect(
        tester.getSize(find.bySemanticsLabel(label)).height,
        greaterThanOrEqualTo(48),
      );
    }
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.scrollDirection, Axis.horizontal);
  });
}
