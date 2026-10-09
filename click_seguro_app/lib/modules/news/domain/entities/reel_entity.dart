import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';

/// Notícia em formato de Reel (data-model de specs/008-reels-curtir-salvar).
///
/// O servidor não informa se a pessoa curtiu: [isLiked] começa `false` e
/// passa a ser o `liked` devolvido pelo toggle (research R2).
class ReelEntity {
  const ReelEntity({
    required this.news,
    required this.content,
    required this.likesCount,
    required this.isSaved,
    this.isLiked = false,
  });

  final NewsItemEntity news;

  /// Texto completo; o trecho da tela sai daqui.
  final String content;
  final int likesCount;
  final bool isLiked;
  final bool isSaved;

  String get id => news.id;

  ReelEntity copyWith({int? likesCount, bool? isLiked, bool? isSaved}) =>
      ReelEntity(
        news: news,
        content: content,
        likesCount: likesCount ?? this.likesCount,
        isLiked: isLiked ?? this.isLiked,
        isSaved: isSaved ?? this.isSaved,
      );
}
