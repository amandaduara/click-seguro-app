import 'package:click_seguro_app/modules/news/domain/entities/news_category_entity.dart';
import 'package:click_seguro_app/modules/news/presentation/extensions/news_presentation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/fake_news_repository.dart';
import '../../fakes/feed_controller_factory.dart';

void main() {
  // Os textos vêm do i18n: cada teste sobe o EasyLocalization.
  Future<void> localized(WidgetTester tester) =>
      pumpLocalized(tester, child: const SizedBox());

  NewsCategoryEntity category(String name) =>
      NewsCategoryEntity(id: name, name: name, slug: name);

  group('relativeDate', () {
    final cases = <String, DateTime>{
      'Hoje': DateTime(2026, 10, 5, 8),
      'Ontem': DateTime(2026, 10, 4, 23, 59),
      'Há 2 dias': DateTime(2026, 10, 3, 1),
      'Há 6 dias': DateTime(2026, 9, 29, 12),
      '28 de set.': DateTime(2026, 9, 28, 12),
      '1 de jan.': DateTime(2026, 1, 1, 12),
    };
    cases.forEach((expected, date) {
      testWidgets('$date → $expected', (tester) async {
        await localized(tester);

        expect(
          newsItem('n1', originalPublishedAt: date).relativeDate(feedNow),
          expected,
        );
      });
    });
  });

  group('categoryLabels', () {
    test('sem categoria → vazio', () {
      expect(newsItem('n1', categories: const []).categoryLabels(), isEmpty);
    });

    test('duas → os dois nomes', () {
      final item = newsItem(
        'n1',
        categories: [category('Phishing'), category('Pix')],
      );

      expect(item.categoryLabels(), ['Phishing', 'Pix']);
    });

    test('quatro → dois nomes e "+2"', () {
      final item = newsItem(
        'n1',
        categories: [
          category('Phishing'),
          category('Pix'),
          category('WhatsApp'),
          category('Bancos'),
        ],
      );

      expect(item.categoryLabels(), ['Phishing', 'Pix', '+2']);
    });
  });

  group('semanticLabel', () {
    testWidgets('título, fonte, data e categorias', (tester) async {
      await localized(tester);
      final item = newsItem('n1', originalPublishedAt: DateTime(2026, 10, 5));

      expect(
        item.semanticLabel(feedNow),
        'Notícia n1, Folha de Teste, Hoje, Phishing',
      );
    });

    testWidgets('sem categoria, sem a última parte', (tester) async {
      await localized(tester);
      final item = newsItem(
        'n1',
        originalPublishedAt: DateTime(2026, 10, 4),
        categories: const [],
      );

      expect(item.semanticLabel(feedNow), 'Notícia n1, Folha de Teste, Ontem');
    });
  });

  group('newCount', () {
    test('conta as das últimas 24 h, sem repetir', () {
      final items = [
        newsItem('a', originalPublishedAt: DateTime(2026, 10, 5, 10)),
        newsItem('b', originalPublishedAt: DateTime(2026, 10, 4, 16)),
        newsItem('a', originalPublishedAt: DateTime(2026, 10, 5, 10)),
        newsItem('c', originalPublishedAt: DateTime(2026, 10, 4, 14)),
        newsItem('d', originalPublishedAt: DateTime(2026, 9, 1)),
      ];

      expect(items.newCount(feedNow), 2);
    });
  });
}
