/// Um alerta: uma notícia nova que ainda não foi (ou já foi) vista. No máximo
/// um por [newsId].
class AlertEntity {
  const AlertEntity({
    required this.newsId,
    required this.title,
    required this.source,
    required this.publishedAt,
    this.isRead = false,
  });

  /// Chave do alerta; vira `/news/<newsId>`.
  final String newsId;
  final String title;
  final String source;

  /// Quando a notícia entrou no app, em UTC.
  final DateTime publishedAt;
  final bool isRead;

  AlertEntity copyWith({bool? isRead}) => AlertEntity(
    newsId: newsId,
    title: title,
    source: source,
    publishedAt: publishedAt,
    isRead: isRead ?? this.isRead,
  );

  /// Dois alertas da mesma notícia são o mesmo alerta.
  @override
  bool operator ==(Object other) =>
      other is AlertEntity && other.newsId == newsId;

  @override
  int get hashCode => newsId.hashCode;
}
