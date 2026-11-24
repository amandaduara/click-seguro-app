import 'package:click_seguro_app/modules/news/data/models/news_detail_model.dart';
import 'package:click_seguro_app/modules/news/data/models/news_list_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/news_fixtures.dart';

void main() {
  group('NewsDetailModel', () {
    test('formato real vira NewsDetailEntity', () {
      final detail = NewsDetailModel.fromJson(
        newsDetailJson(
          id: 'n1',
          content: 'Texto do servidor',
          likesCount: 12,
          readsCount: 5,
          isSaved: true,
          imageUrl: 'https://img.test/d.jpg',
          suggestedModule: suggestedModuleJson(iconUrl: 'https://img.test/i'),
        ),
      ).toEntity();

      expect(detail.id, 'n1');
      expect(detail.news.title, 'Golpe do Pix');
      expect(detail.news.source, 'Folha de Teste');
      expect(detail.news.sourceUrl, 'https://fonte.test/n1');
      expect(detail.news.imageUrl, 'https://img.test/d.jpg');
      expect(detail.news.categories.single.slug, 'phishing');
      expect(detail.content, 'Texto do servidor');
      expect(detail.likesCount, 12);
      expect(detail.readsCount, 5);
      expect(detail.news.interaction.isSaved, isTrue);
      expect(detail.suggestedModule!.id, 'm1');
    });

    test('likesCount e readsCount numéricos com casa decimal viram int', () {
      final json = newsDetailJson(id: 'n1')
        ..['likesCount'] = 7.0
        ..['readsCount'] = 3.0;

      final detail = NewsDetailModel.fromJson(json).toEntity();

      expect(detail.likesCount, 7);
      expect(detail.readsCount, 3);
    });

    test('content, likesCount e readsCount ausentes têm padrão', () {
      final json = newsDetailJson(id: 'n1')
        ..remove('content')
        ..remove('likesCount')
        ..remove('readsCount');

      final detail = NewsDetailModel.fromJson(json).toEntity();

      expect(detail.content, '');
      expect(detail.likesCount, 0);
      expect(detail.readsCount, 0);
    });

    test('suggestedModule presente: iconUrl vazio vira null', () {
      final json = newsDetailJson(
        id: 'n1',
        suggestedModule: suggestedModuleJson(lessonsCount: 4)
          ..['iconUrl'] = ''
          ..['description'] = '',
      );

      final module = NewsDetailModel.fromJson(json).toEntity().suggestedModule!;

      expect(module.id, 'm1');
      expect(module.title, 'Golpes no WhatsApp');
      expect(module.description, '');
      expect(module.iconUrl, isNull);
      expect(module.lessonsCount, 4);
    });

    test('suggestedModule com iconUrl mantém o endereço', () {
      final json = newsDetailJson(
        id: 'n1',
        suggestedModule: suggestedModuleJson(iconUrl: 'https://img.test/i'),
      );

      final module = NewsDetailModel.fromJson(json).toEntity().suggestedModule!;

      expect(module.iconUrl, 'https://img.test/i');
    });

    test('suggestedModule null, ausente ou sem id vira null', () {
      final withNull = newsDetailJson(id: 'n1');
      final absent = newsDetailJson(id: 'n1')..remove('suggestedModule');
      final noId = newsDetailJson(id: 'n1', suggestedModule: {'title': 'x'});

      for (final json in [withNull, absent, noId]) {
        expect(
          NewsDetailModel.fromJson(json).toEntity().suggestedModule,
          isNull,
        );
      }
    });

    for (final field in [
      'id',
      'title',
      'source',
      'sourceUrl',
      'originalPublishedAt',
    ]) {
      test('sem $field lança', () {
        final json = newsDetailJson(id: 'n1')..remove(field);

        expect(() => NewsDetailModel.fromJson(json), throwsA(anything));
      });
    }
  });

  group('lista de salvas', () {
    test(
      'item sem content, createdAt e isHighlight passa pelo NewsListModel',
      () {
        final json = savedListJson(
          items: [newsItemJson(id: 'n1', isSaved: true)],
          page: 2,
          hasNextPage: true,
        );

        final item = (json['data'] as List).single as Map<String, dynamic>;
        expect(item.containsKey('content'), isFalse);
        expect(item.containsKey('createdAt'), isFalse);
        expect(item.containsKey('isHighlight'), isFalse);

        final page = NewsListModel.fromJson(json).toEntity();

        expect(page.items.single.id, 'n1');
        expect(page.items.single.interaction.isSaved, isTrue);
        expect(page.items.single.isHighlight, isFalse);
        expect(page.page, 2);
        expect(page.hasMore, isTrue);
      },
    );
  });
}
