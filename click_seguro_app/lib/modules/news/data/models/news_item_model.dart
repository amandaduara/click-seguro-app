import 'package:click_seguro_app/modules/news/data/models/news_category_model.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';

/// Item de notícia do feed, da lista ou dos Reels (formato conferido no
/// servidor, research R0 de specs/006-feed-inicio). Não há resumo.
class NewsItemModel {
  const NewsItemModel({
    required this.id,
    required this.title,
    required this.source,
    required this.sourceUrl,
    required this.originalPublishedAt,
    required this.categories,
    this.imageUrl,
    this.publishedAt,
    this.isHighlight = false,
    this.isRead = false,
    this.isSaved = false,
    this.isLiked = false,
  });

  factory NewsItemModel.fromJson(Map<String, dynamic> json) {
    final interaction = json['interaction'] as Map<String, dynamic>?;
    final image = json['imageUrl'] as String?;
    final published = json['publishedAt'] as String?;
    return NewsItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      source: json['source'] as String,
      sourceUrl: json['sourceUrl'] as String,
      imageUrl: image == null || image.isEmpty ? null : image,
      originalPublishedAt: DateTime.parse(
        json['originalPublishedAt'] as String,
      ),
      publishedAt: published == null ? null : DateTime.parse(published),
      isHighlight: json['isHighlight'] as bool? ?? false,
      categories: [
        for (final category in json['categories'] as List? ?? const [])
          NewsCategoryModel.fromJson(category as Map<String, dynamic>),
      ],
      isRead: interaction?['isRead'] as bool? ?? false,
      isSaved: interaction?['isSaved'] as bool? ?? false,
      isLiked: interaction?['isLiked'] as bool? ?? false,
    );
  }

  final String id;
  final String title;
  final String source;
  final String sourceUrl;
  final String? imageUrl;
  final DateTime originalPublishedAt;
  final DateTime? publishedAt;
  final bool isHighlight;
  final List<NewsCategoryModel> categories;
  final bool isRead;
  final bool isSaved;
  final bool isLiked;

  NewsItemEntity toEntity() => NewsItemEntity(
    id: id,
    title: title,
    source: source,
    sourceUrl: sourceUrl,
    imageUrl: imageUrl,
    originalPublishedAt: originalPublishedAt,
    publishedAt: publishedAt,
    isHighlight: isHighlight,
    categories: [for (final category in categories) category.toEntity()],
    interaction: NewsInteraction(
      isRead: isRead,
      isSaved: isSaved,
      isLiked: isLiked,
    ),
  );
}

List<NewsItemModel> parseNewsItems(Object? json) => [
  for (final item in json as List? ?? const [])
    NewsItemModel.fromJson(item as Map<String, dynamic>),
];
