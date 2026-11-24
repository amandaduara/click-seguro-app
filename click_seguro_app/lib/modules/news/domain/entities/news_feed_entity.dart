import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';

/// Primeira carga do feed sem filtro.
class NewsFeedEntity {
  const NewsFeedEntity({
    required this.highlights,
    required this.recommended,
    required this.recent,
    required this.reels,
    this.isFromCache = false,
  });

  final List<NewsItemEntity> highlights;

  /// Vazio para o visitante.
  final List<NewsItemEntity> recommended;
  final NewsPageEntity recent;

  /// Carrossel "Novidades"; vazio se os Reels falharem.
  final List<NewsItemEntity> reels;

  /// Veio da cópia guardada no aparelho (sem internet).
  final bool isFromCache;
}
