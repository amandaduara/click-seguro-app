import 'package:click_seguro_app/modules/news/domain/entities/news_category_entity.dart';

/// Estado da pessoa em relação à notícia. O servidor manda tudo `false`
/// também para o visitante.
class NewsInteraction {
  const NewsInteraction({
    this.isRead = false,
    this.isSaved = false,
    this.isLiked = false,
  });

  final bool isRead;
  final bool isSaved;
  final bool isLiked;
}

/// Notícia do feed, da lista filtrada ou dos Reels.
class NewsItemEntity {
  const NewsItemEntity({
    required this.id,
    required this.title,
    required this.source,
    required this.sourceUrl,
    required this.originalPublishedAt,
    this.imageUrl,
    this.publishedAt,
    this.isHighlight = false,
    this.categories = const [],
    this.interaction = const NewsInteraction(),
  });

  final String id;
  final String title;
  final String source;
  final String sourceUrl;
  final String? imageUrl;

  /// Data da fonte original: a exibida e a base da contagem de novas.
  final DateTime originalPublishedAt;

  /// Entrada no app; define a ordem do servidor.
  final DateTime? publishedAt;
  final bool isHighlight;
  final List<NewsCategoryEntity> categories;
  final NewsInteraction interaction;
}
