/// Categoria de notícia vinda da API (RN-002); o filtro usa o [slug].
class NewsCategoryEntity {
  const NewsCategoryEntity({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;
}
