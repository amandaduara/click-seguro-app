import 'package:click_seguro_app/modules/news/data/models/news_item_model.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_feed_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';

/// `GET /app/news/feed?page` (+ os Reels do carrossel na 1ª página).
class NewsFeedModel {
  const NewsFeedModel({
    required this.highlights,
    required this.recommended,
    required this.recent,
    required this.nextCursor,
    required this.reels,
    required this.page,
  });

  /// [reels] é a resposta de `/app/news/reels`; `null` nas páginas seguintes.
  factory NewsFeedModel.fromJson(
    Map<String, dynamic> feed,
    Map<String, dynamic>? reels, {
    int page = 1,
  }) {
    final recent = feed['recent'] as Map<String, dynamic>;
    return NewsFeedModel(
      highlights: parseNewsItems(feed['highlights']),
      recommended: parseNewsItems(feed['recommended']),
      recent: parseNewsItems(recent['data']),
      nextCursor: recent['nextCursor'] as String?,
      reels: parseNewsItems(reels?['data']),
      page: page,
    );
  }

  /// Notícias por página do feed e das listas.
  static const int pageSize = 20;

  final List<NewsItemModel> highlights;
  final List<NewsItemModel> recommended;
  final List<NewsItemModel> recent;
  final String? nextCursor;
  final List<NewsItemModel> reels;
  final int page;

  /// O servidor só devolve `nextCursor: null` na página vazia; uma página
  /// incompleta também é a última (research R0/R1).
  bool get hasMore => nextCursor != null && recent.length >= pageSize;

  NewsPageEntity toPage() => NewsPageEntity(
    items: [for (final item in recent) item.toEntity()],
    hasMore: hasMore,
    page: page,
  );

  NewsFeedEntity toEntity({bool isFromCache = false}) => NewsFeedEntity(
    highlights: [for (final item in highlights) item.toEntity()],
    recommended: [for (final item in recommended) item.toEntity()],
    recent: toPage(),
    reels: [for (final item in reels) item.toEntity()],
    isFromCache: isFromCache,
  );
}
