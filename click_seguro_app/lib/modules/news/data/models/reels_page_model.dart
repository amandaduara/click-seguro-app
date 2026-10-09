import 'package:click_seguro_app/modules/news/data/models/reel_model.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reels_page_entity.dart';

/// `GET /app/news/reels`: `{data, nextCursor}`.
class ReelsPageModel {
  const ReelsPageModel({required this.items, required this.nextCursor});

  /// Um Reel malformado é descartado; os demais aparecem (research R8). Sem
  /// `data`, lança: o `toModel` transforma em `invalidResponse`.
  factory ReelsPageModel.fromJson(Map<String, dynamic> json) {
    final items = <ReelModel>[];
    for (final item in json['data'] as List) {
      try {
        items.add(ReelModel.fromJson(item as Map<String, dynamic>));
      } on TypeError {
        continue;
      } on FormatException {
        continue;
      }
    }
    return ReelsPageModel(
      items: items,
      nextCursor: json['nextCursor'] as String?,
    );
  }

  final List<ReelModel> items;
  final String? nextCursor;

  ReelsPageEntity toEntity() => ReelsPageEntity(
    items: [for (final item in items) item.toEntity()],
    nextCursor: nextCursor,
  );
}
