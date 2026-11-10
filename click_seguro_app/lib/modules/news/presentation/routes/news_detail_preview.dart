import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';

/// O que o cartão já tem da notícia, passado como `extra` de `/news/:id`
/// (specs/022 R9, FR-017): o detalhe mostra o cabeçalho na hora e só o
/// corpo espera a carga.
class NewsDetailPreview {
  const NewsDetailPreview({required this.item, required this.heroTag});

  /// Tag do `Hero` da imagem: `news-image-<seção>-<id>`, porque a mesma
  /// notícia pode aparecer em duas seções da mesma tela.
  static String tagFor(String section, String newsId) =>
      'news-image-$section-$newsId';

  final NewsItemEntity item;
  final String heroTag;
}
