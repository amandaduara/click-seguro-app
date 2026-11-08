import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reel_entity.dart';

/// Dados de exemplo para os esqueletos do feed e dos Reels (specs/022 R8).
abstract final class NewsPlaceholders {
  static final DateTime _date = DateTime(2026);

  static NewsItemEntity item(int index) => NewsItemEntity(
    id: 'placeholder-$index',
    title: SafeSkeleton.text(9),
    source: SafeSkeleton.text(1),
    sourceUrl: '',
    originalPublishedAt: _date,
    publishedAt: _date,
  );

  static ReelEntity reel() => ReelEntity(
    news: item(0),
    content: SafeSkeleton.text(40),
    likesCount: 0,
    isSaved: false,
  );
}
