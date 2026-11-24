import 'package:click_seguro_app/modules/news/data/models/like_result_model.dart';
import 'package:click_seguro_app/modules/news/data/models/reel_model.dart';
import 'package:click_seguro_app/modules/news/data/models/reels_page_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/news_fixtures.dart';

void main() {
  group('ReelModel', () {
    test('formato real vira ReelEntity, sem curtida marcada', () {
      final reel = ReelModel.fromJson(
        reelItemJson(id: 'r1', likesCount: 12, isSaved: true, content: 'Txt'),
      ).toEntity();

      expect(reel.id, 'r1');
      expect(reel.news.title, 'Golpe do Pix');
      expect(reel.news.sourceUrl, 'https://fonte.test/r1');
      expect(reel.news.categories.single.slug, 'phishing');
      expect(reel.content, 'Txt');
      expect(reel.likesCount, 12);
      expect(reel.isSaved, isTrue);
      expect(reel.isLiked, isFalse);
    });

    test('likesCount numérico com casa decimal vira int', () {
      final json = reelItemJson(id: 'r1')..['likesCount'] = 7.0;

      expect(ReelModel.fromJson(json).toEntity().likesCount, 7);
    });

    test('content, likesCount e interaction ausentes têm padrão', () {
      final json = reelItemJson(id: 'r1')
        ..remove('content')
        ..remove('likesCount')
        ..remove('interaction');

      final reel = ReelModel.fromJson(json).toEntity();

      expect(reel.content, '');
      expect(reel.likesCount, 0);
      expect(reel.isSaved, isFalse);
    });
  });

  group('ReelsPageModel', () {
    test('mantém a ordem e lê o cursor', () {
      final page = ReelsPageModel.fromJson(
        reelsJson(
          items: [
            reelItemJson(id: 'r1'),
            reelItemJson(id: 'r2'),
          ],
          nextCursor: 'abc',
        ),
      ).toEntity();

      expect(page.items.map((r) => r.id), ['r1', 'r2']);
      expect(page.nextCursor, 'abc');
      expect(page.hasMore, isTrue);
    });

    test('cursor nulo é o fim', () {
      final page = ReelsPageModel.fromJson(reelsJson()).toEntity();

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test('descarta só o Reel malformado', () {
      final broken = reelItemJson(id: 'r2')..remove('title');
      final noDate = reelItemJson(id: 'r3')..['originalPublishedAt'] = 'x';

      final page = ReelsPageModel.fromJson(
        reelsJson(
          items: [
            reelItemJson(id: 'r1'),
            broken,
            noDate,
          ],
        ),
      ).toEntity();

      expect(page.items.map((r) => r.id), ['r1']);
    });

    test('sem data lança', () {
      expect(
        () => ReelsPageModel.fromJson({'nextCursor': null}),
        throwsA(anything),
      );
    });
  });

  test('LikeResultModel', () {
    final result = LikeResultModel.fromJson(
      likeJson(liked: true, likesCount: 42),
    ).toEntity();

    expect(result.liked, isTrue);
    expect(result.likesCount, 42);
  });
}
