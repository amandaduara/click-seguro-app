import 'package:click_seguro_app/modules/news/domain/entities/reel_entity.dart';

/// Uma parte dos Reels, paginada por cursor.
class ReelsPageEntity {
  const ReelsPageEntity({required this.items, required this.nextCursor});

  final List<ReelEntity> items;

  /// Onde continuar; `null` = fim.
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}

/// Junta partes sem repetir Reel (CB-007), como o `appendUnique` do feed.
extension ReelsMerge on List<ReelEntity> {
  /// Lista com os Reels de [page] cujo `id` ainda não está nela, e quantos
  /// entraram.
  (List<ReelEntity>, int) appendUniqueReels(List<ReelEntity> page) {
    final seen = {for (final reel in this) reel.id};
    final merged = [...this];
    for (final reel in page) {
      if (seen.add(reel.id)) merged.add(reel);
    }
    return (merged, merged.length - length);
  }
}
