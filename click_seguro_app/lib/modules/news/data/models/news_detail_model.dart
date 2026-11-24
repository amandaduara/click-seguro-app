import 'package:click_seguro_app/modules/news/data/models/news_item_model.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_detail_entity.dart';

/// Módulo sugerido de `GET /app/news/{id}`; `null` quando falta o `id`.
class SuggestedModuleModel {
  const SuggestedModuleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.lessonsCount,
    this.iconUrl,
  });

  static SuggestedModuleModel? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final id = json['id'];
    if (id is! String || id.isEmpty) return null;
    final icon = json['iconUrl'] as String?;
    return SuggestedModuleModel(
      id: id,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconUrl: icon == null || icon.isEmpty ? null : icon,
      lessonsCount: (json['lessonsCount'] as num? ?? 0).toInt(),
    );
  }

  final String id;
  final String title;
  final String description;
  final String? iconUrl;
  final int lessonsCount;

  SuggestedModuleEntity toEntity() => SuggestedModuleEntity(
    id: id,
    title: title,
    description: description,
    iconUrl: iconUrl,
    lessonsCount: lessonsCount,
  );
}

/// `GET /app/news/{id}`: notícia + `content`, contadores e módulo sugerido
/// (research R0 de specs/010-detalhe-noticia).
class NewsDetailModel {
  const NewsDetailModel({
    required this.news,
    required this.content,
    required this.likesCount,
    required this.readsCount,
    this.suggestedModule,
  });

  factory NewsDetailModel.fromJson(Map<String, dynamic> json) =>
      NewsDetailModel(
        news: NewsItemModel.fromJson(json),
        content: json['content'] as String? ?? '',
        likesCount: (json['likesCount'] as num? ?? 0).toInt(),
        readsCount: (json['readsCount'] as num? ?? 0).toInt(),
        suggestedModule: SuggestedModuleModel.tryFromJson(
          json['suggestedModule'],
        ),
      );

  final NewsItemModel news;
  final String content;
  final int likesCount;
  final int readsCount;
  final SuggestedModuleModel? suggestedModule;

  NewsDetailEntity toEntity() => NewsDetailEntity(
    news: news.toEntity(),
    content: content,
    likesCount: likesCount,
    readsCount: readsCount,
    suggestedModule: suggestedModule?.toEntity(),
  );
}
