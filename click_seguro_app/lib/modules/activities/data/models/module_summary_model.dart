import 'package:click_seguro_app/modules/activities/domain/entities/module_summary_entity.dart';

/// Um item de `modules` em `GET /app/educational/modules`. O
/// `progressPercent` do serviço é ignorado: o app calcula.
abstract final class ModuleSummaryModel {
  /// `null` quando falta `id` ou `title`: o módulo é descartado.
  static ModuleSummaryEntity? fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    final Object? title = json['title'];
    if (id is! String || id.isEmpty || title is! String || title.isEmpty) {
      return null;
    }
    final Object? icon = json['iconUrl'];
    return ModuleSummaryEntity(
      id: id,
      title: title,
      description: json['description'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      iconUrl: icon is String && icon.isNotEmpty ? icon : null,
      lessonsCount: (json['lessonsCount'] as num?)?.toInt() ?? 0,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
    );
  }
}
