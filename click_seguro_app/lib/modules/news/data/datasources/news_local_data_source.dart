/// Última 1ª carga do feed sem filtro, para uso sem internet (RNF-002).
class CachedFeed {
  const CachedFeed({
    required this.feedJson,
    required this.reelsJson,
    required this.savedAt,
  });

  final Map<String, dynamic> feedJson;
  final Map<String, dynamic> reelsJson;
  final DateTime savedAt;
}

abstract class NewsLocalDataSource {
  /// `null` se não houver cópia ou ela estiver ilegível.
  Future<CachedFeed?> readFeed();

  /// Substitui a cópia anterior.
  Future<void> writeFeed(
    Map<String, dynamic> feedJson,
    Map<String, dynamic> reelsJson,
  );
}
