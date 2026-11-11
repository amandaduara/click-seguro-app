import 'package:click_seguro_app/core/widgets/safe_badge.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_category_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/widgets/news_detail_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_news_repository.dart';

void main() {
  Future<void> pumpHeader(WidgetTester tester, {int? readingMinutes}) =>
      pumpLocalized(
        tester,
        child: Scaffold(
          body: ListView(
            children: [
              NewsDetailHeader(
                news: newsItem(
                  'n1',
                  categories: const [
                    NewsCategoryEntity(id: 'c1', name: 'Golpe', slug: 'golpe'),
                    NewsCategoryEntity(
                      id: 'c2',
                      name: 'WhatsApp',
                      slug: 'whatsapp',
                    ),
                  ],
                ),
                now: DateTime(2026, 9, 21),
                readingMinutes: readingMinutes,
              ),
            ],
          ),
        ),
      );

  testWidgets('selos das categorias, a primeira em coral, e o título', (
    tester,
  ) async {
    await pumpHeader(tester);

    final List<SafeBadge> badges = tester
        .widgetList<SafeBadge>(find.byType(SafeBadge))
        .toList();
    expect(badges.map((b) => b.tone), [
      SafeBadgeTone.primary,
      SafeBadgeTone.secondary,
    ]);
    expect(find.text('Golpe'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Notícia n1'), findsOneWidget);
    // Os selos vêm antes do título.
    expect(
      tester.getTopLeft(find.text('Golpe')).dy,
      lessThan(tester.getTopLeft(find.text('Notícia n1')).dy),
    );
  });

  testWidgets('prévia, sem tempo de leitura: fonte e data', (tester) async {
    await pumpHeader(tester);

    expect(find.text('Folha de Teste · Ontem'), findsOneWidget);
    expect(find.textContaining('min de leitura'), findsNothing);
  });

  testWidgets('com o detalhe: fonte, data e tempo de leitura, também lidos', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpHeader(tester, readingMinutes: 3);

    expect(
      find.text('Folha de Teste · Ontem · 3 min de leitura'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Notícia n1, Folha de Teste, Ontem, 3 min de leitura',
      ),
      findsOneWidget,
    );
    // As categorias num nó só, separado do título.
    expect(find.bySemanticsLabel('Golpe\nWhatsApp'), findsOneWidget);
    handle.dispose();
  });
}
