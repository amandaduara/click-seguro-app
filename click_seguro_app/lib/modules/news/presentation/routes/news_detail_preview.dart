import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';

/// O que o cartão já tem da notícia, passado como `extra` de `/news/:id`
/// (specs/022 R9, FR-017): o detalhe mostra o cabeçalho na hora e só o
/// corpo espera a carga.
class NewsDetailPreview {
  const NewsDetailPreview({required this.item, this.heroTag, this.actions});

  /// Tag do `Hero` da imagem: `news-image-<seção>-<id>`, porque a mesma
  /// notícia pode aparecer em duas seções da mesma tela.
  static String tagFor(String section, String newsId) =>
      'news-image-$section-$newsId';

  final NewsItemEntity item;

  /// `null` → a capa não voa (o Reel não tem `Hero` de imagem).
  final String? heroTag;

  /// Aberto por um Reel: curtir, salvar e compartilhar voam da coluna do
  /// Reel para o topo do detalhe e aparecem antes da carga.
  final NewsActionsPreview? actions;
}

/// Estado de curtir e salvar que o Reel já mostra e as tags dos `Hero` dos
/// três botões, as mesmas em `ReelActions` e `NewsDetailActions`.
class NewsActionsPreview {
  const NewsActionsPreview({
    required this.newsId,
    required this.isLiked,
    required this.likesCount,
    required this.isSaved,
  });

  final String newsId;
  final bool isLiked;
  final int likesCount;

  /// Já resolvido: o visitante vê sempre `false`.
  final bool isSaved;

  /// `reel-like-<id>`, `reel-save-<id>` e `reel-share-<id>`.
  static NewsActionTags tagsFor(String newsId) => (
    like: 'reel-like-$newsId',
    save: 'reel-save-$newsId',
    share: 'reel-share-$newsId',
  );

  NewsActionTags get tags => tagsFor(newsId);
}

/// Tags dos `Hero` de curtir, salvar e compartilhar.
typedef NewsActionTags = ({String like, String save, String share});
