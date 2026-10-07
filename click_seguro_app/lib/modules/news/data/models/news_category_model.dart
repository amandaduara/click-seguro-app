import 'package:click_seguro_app/modules/news/domain/entities/news_category_entity.dart';

/// Categoria de `GET /categories` ou embutida numa notícia.
class NewsCategoryModel {
  const NewsCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.isActive = true,
  });

  factory NewsCategoryModel.fromJson(Map<String, dynamic> json) =>
      NewsCategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        isActive: json['isActive'] as bool? ?? true,
      );

  final String id;
  final String name;
  final String slug;
  final bool isActive;

  NewsCategoryEntity toEntity() =>
      NewsCategoryEntity(id: id, name: name, slug: slug);
}
