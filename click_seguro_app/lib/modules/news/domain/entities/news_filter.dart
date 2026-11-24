/// Texto mínimo para buscar (FR-017 de specs/006-feed-inicio).
const int minSearchLength = 2;

/// Categoria e busca da lista. Vazio = feed completo.
class NewsFilter {
  const NewsFilter({this.categorySlug, this.search = ''});

  /// `null` = "Todas".
  final String? categorySlug;
  final String search;

  String get normalizedSearch => search.trim();

  bool get hasSearch => normalizedSearch.length >= minSearchLength;

  bool get isEmpty => categorySlug == null && !hasSearch;

  NewsFilter copyWith({
    String? categorySlug,
    bool clearCategory = false,
    String? search,
  }) => NewsFilter(
    categorySlug: clearCategory ? null : categorySlug ?? this.categorySlug,
    search: search ?? this.search,
  );

  @override
  bool operator ==(Object other) =>
      other is NewsFilter &&
      other.categorySlug == categorySlug &&
      other.normalizedSearch == normalizedSearch;

  @override
  int get hashCode => Object.hash(categorySlug, normalizedSearch);
}
