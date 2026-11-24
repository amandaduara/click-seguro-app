import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';

/// Uma parte de uma lista paginada.
class NewsPageEntity {
  const NewsPageEntity({
    required this.items,
    required this.hasMore,
    required this.page,
  });

  final List<NewsItemEntity> items;
  final bool hasMore;
  final int page;
}

/// Junta páginas sem repetir notícia (CB-007), mesmo que o servidor devolva
/// itens já vistos (research R1 de specs/006-feed-inicio).
extension NewsItemsMerge on List<NewsItemEntity> {
  /// Lista com os itens de [page] cujo `id` ainda não está nela, e quantos
  /// entraram.
  (List<NewsItemEntity>, int) appendUnique(List<NewsItemEntity> page) {
    final seen = {for (final item in this) item.id};
    final merged = [...this];
    for (final item in page) {
      if (seen.add(item.id)) merged.add(item);
    }
    return (merged, merged.length - length);
  }
}
