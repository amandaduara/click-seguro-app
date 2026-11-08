import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';

/// Mudança confirmada pelo servidor na interação da pessoa com uma notícia
/// (lida, salva, curtida). Campo `null` = não mudou. Feed e Reels corrigem o
/// item na tela sem recarregar (specs/022 FR-005, research R7).
class NewsInteractionChange {
  const NewsInteractionChange({
    required this.newsId,
    this.isRead,
    this.isSaved,
    this.isLiked,
    this.likesCount,
  });

  final String newsId;
  final bool? isRead;
  final bool? isSaved;
  final bool? isLiked;

  /// Total de curtidas devolvido pelo servidor junto de [isLiked].
  final int? likesCount;

  /// [interaction] com esta mudança aplicada.
  NewsInteraction applyTo(NewsInteraction interaction) => NewsInteraction(
    isRead: isRead ?? interaction.isRead,
    isSaved: isSaved ?? interaction.isSaved,
    isLiked: isLiked ?? interaction.isLiked,
  );
}
