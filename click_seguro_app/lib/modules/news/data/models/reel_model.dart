import 'package:click_seguro_app/modules/news/data/models/news_item_model.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reel_entity.dart';

/// Item de `GET /app/news/reels`: notícia + `content` + `likesCount`; a
/// `interaction` só traz `isSaved` (research R0 de specs/008).
class ReelModel {
  const ReelModel({
    required this.news,
    required this.content,
    required this.likesCount,
  });

  factory ReelModel.fromJson(Map<String, dynamic> json) => ReelModel(
    news: NewsItemModel.fromJson(json),
    content: json['content'] as String? ?? '',
    likesCount: (json['likesCount'] as num? ?? 0).toInt(),
  );

  final NewsItemModel news;
  final String content;
  final int likesCount;

  ReelEntity toEntity() => ReelEntity(
    news: news.toEntity(),
    content: content,
    likesCount: likesCount,
    isSaved: news.isSaved,
  );
}
