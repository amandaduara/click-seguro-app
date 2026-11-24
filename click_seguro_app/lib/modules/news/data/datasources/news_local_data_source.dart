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

  /// JSON cru da notícia [id] guardada neste aparelho; `null` se não houver,
  /// for de outra conta ou estiver ilegível (specs/010, R2 e R3).
  Future<Map<String, dynamic>?> readDetail(String id);

  /// Guarda o JSON cru de uma notícia aberta (as últimas 30, mais recente
  /// primeiro, sem repetir o id).
  Future<void> writeDetail(Map<String, dynamic> json);

  /// JSON cru da 1ª página das salvas; `null` como em [readDetail].
  Future<Map<String, dynamic>?> readSavedPage();

  /// Substitui a cópia da 1ª página das salvas.
  Future<void> writeSavedPage(Map<String, dynamic> json);

  /// Apaga as cópias ligadas à conta (detalhes e salvas); o feed fica.
  Future<void> clearAccountCopies();
}
