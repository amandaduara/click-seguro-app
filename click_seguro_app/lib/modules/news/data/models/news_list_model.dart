import 'package:click_seguro_app/modules/news/data/models/news_item_model.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';

/// `GET /app/news`: `{data, meta}`, paginado por página.
class NewsListModel {
  const NewsListModel({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  factory NewsListModel.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;
    return NewsListModel(
      items: parseNewsItems(json['data']),
      page: meta['page'] as int,
      hasMore: meta['hasNextPage'] as bool,
    );
  }

  final List<NewsItemModel> items;
  final int page;
  final bool hasMore;

  NewsPageEntity toEntity() => NewsPageEntity(
    items: [for (final item in items) item.toEntity()],
    hasMore: hasMore,
    page: page,
  );
}
