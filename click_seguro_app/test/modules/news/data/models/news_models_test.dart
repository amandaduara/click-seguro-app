import 'package:click_seguro_app/modules/news/data/models/news_category_model.dart';
import 'package:click_seguro_app/modules/news/data/models/news_feed_model.dart';
import 'package:click_seguro_app/modules/news/data/models/news_item_model.dart';
import 'package:click_seguro_app/modules/news/data/models/news_list_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/news_fixtures.dart';

void main() {
  group('NewsItemModel', () {
    test('lê todos os campos do servidor', () {
      final item = NewsItemModel.fromJson(
        newsItemJson(
          id: 'n1',
          originalPublishedAt: DateTime.utc(2026, 10, 4, 3),
          isSaved: true,
        ),
      ).toEntity();

      expect(item.id, 'n1');
      expect(item.title, 'Golpe do Pix');
      expect(item.source, 'Folha de Teste');
      expect(item.sourceUrl, 'https://fonte.test/n1');
      expect(item.imageUrl, 'https://img.test/n.jpg');
      expect(item.originalPublishedAt, DateTime.utc(2026, 10, 4, 3));
      expect(item.publishedAt, DateTime.utc(2026, 10, 5, 12));
      expect(item.isHighlight, isFalse);
      expect(item.categories.single.slug, 'phishing');
      expect(item.categories.single.name, 'Phishing');
      expect(item.interaction.isSaved, isTrue);
      expect(item.interaction.isRead, isFalse);
    });

    test('opcionais ausentes viram padrões seguros', () {
      final json = newsItemJson(id: 'n1')
        ..remove('categories')
        ..remove('interaction')
        ..remove('isHighlight')
        ..remove('publishedAt')
        ..['imageUrl'] = '';

      final item = NewsItemModel.fromJson(json).toEntity();

      expect(item.imageUrl, isNull);
      expect(item.categories, isEmpty);
      expect(item.interaction.isRead, isFalse);
      expect(item.interaction.isSaved, isFalse);
      expect(item.isHighlight, isFalse);
      expect(item.publishedAt, isNull);
    });

    for (final field in ['id', 'title', 'originalPublishedAt']) {
      test('sem $field lança', () {
        final json = newsItemJson(id: 'n1')..remove(field);

        expect(() => NewsItemModel.fromJson(json), throwsA(anything));
      });
    }
  });

  test('NewsCategoryModel lê nome, slug e se está ativa', () {
    final model = NewsCategoryModel.fromJson(categoriesJson.last);

    expect(model.slug, 'antiga');
    expect(model.isActive, isFalse);
    expect(model.toEntity().name, 'Antiga');
  });

  group('NewsListModel', () {
    test('hasMore vem de meta.hasNextPage', () {
      final page = NewsListModel.fromJson(
        newsListJson(items: newsItemsJson(2), page: 3, hasNextPage: true),
      ).toEntity();

      expect(page.items.map((n) => n.id), ['n1', 'n2']);
      expect(page.page, 3);
      expect(page.hasMore, isTrue);
    });
  });

  group('NewsFeedModel', () {
    test('seções, Reels e primeira página', () {
      final feed = NewsFeedModel.fromJson(
        feedJson(
          highlights: [newsItemJson(id: 'h1')],
          recommended: [newsItemJson(id: 'r1')],
          recent: newsItemsJson(20),
          nextCursor: 'abc',
        ),
        reelsJson(items: [reelItemJson(id: 'reel1')]),
      ).toEntity();

      expect(feed.highlights.single.id, 'h1');
      expect(feed.recommended.single.id, 'r1');
      expect(feed.reels.single.id, 'reel1');
      expect(feed.recent.items, hasLength(20));
      expect(feed.recent.page, 1);
      expect(feed.recent.hasMore, isTrue);
      expect(feed.isFromCache, isFalse);
    });

    test('fim quando nextCursor é nulo', () {
      final feed = NewsFeedModel.fromJson(
        feedJson(recent: newsItemsJson(20)),
        reelsJson(),
      ).toEntity();

      expect(feed.recent.hasMore, isFalse);
    });

    test('fim quando vieram menos itens que o limite (servidor real)', () {
      final page = NewsFeedModel.fromJson(
        feedJson(recent: newsItemsJson(2), nextCursor: 'abc'),
        null,
        page: 2,
      ).toEntity().recent;

      expect(page.hasMore, isFalse);
      expect(page.page, 2);
    });
  });
}
