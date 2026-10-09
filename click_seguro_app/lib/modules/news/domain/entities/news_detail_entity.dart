import 'package:click_seguro_app/modules/common/services/external_launcher_service.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';

/// Módulo de atividades sugerido para a notícia (data-model de
/// specs/010-detalhe-noticia).
class SuggestedModuleEntity {
  const SuggestedModuleEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.lessonsCount,
    this.iconUrl,
  });

  final String id;
  final String title;

  /// Pode ser vazio.
  final String description;
  final String? iconUrl;

  /// Número de perguntas mostrado no bloco.
  final int lessonsCount;
}

/// Notícia completa. Compõe [NewsItemEntity], como o `ReelEntity` da 008.
class NewsDetailEntity {
  const NewsDetailEntity({
    required this.news,
    required this.content,
    required this.likesCount,
    required this.readsCount,
    this.suggestedModule,
  });

  final NewsItemEntity news;

  /// Texto completo; pode ser vazio (a tela avisa que não está disponível).
  final String content;
  final int likesCount;
  final int readsCount;

  /// `null` → sem bloco de atividade relacionada.
  final SuggestedModuleEntity? suggestedModule;

  String get id => news.id;

  bool get hasSource => isOpenableWebUrl(news.sourceUrl);

  bool get isSaved => news.interaction.isSaved;

  NewsDetailEntity copyWith({bool? isSaved}) => NewsDetailEntity(
    news: NewsItemEntity(
      id: news.id,
      title: news.title,
      source: news.source,
      sourceUrl: news.sourceUrl,
      imageUrl: news.imageUrl,
      originalPublishedAt: news.originalPublishedAt,
      publishedAt: news.publishedAt,
      isHighlight: news.isHighlight,
      categories: news.categories,
      interaction: NewsInteraction(
        isRead: news.interaction.isRead,
        isSaved: isSaved ?? news.interaction.isSaved,
        isLiked: news.interaction.isLiked,
      ),
    ),
    content: content,
    likesCount: likesCount,
    readsCount: readsCount,
    suggestedModule: suggestedModule,
  );
}

/// Detalhe devolvido pelo repository. [isFromCache] `true`: veio da cópia do
/// aparelho (aviso de offline; não registra leitura).
class NewsDetailResult {
  const NewsDetailResult({required this.detail, required this.isFromCache});

  final NewsDetailEntity detail;
  final bool isFromCache;
}
