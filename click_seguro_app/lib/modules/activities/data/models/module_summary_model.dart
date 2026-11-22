import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_summary_entity.dart';

/// Um item de `modules` em `GET /app/educational/modules`. O
/// `progressPercent` do serviço é ignorado: o app calcula. O contrato atual
/// não traz `score`/`totalScore` na lista (só no detalhe, em `progress`); se
/// vierem, são lidos com os mesmos nomes (specs/025).
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
      score: _scoreFromJson(json),
    );
  }

  /// `totalScore` ausente ou 0: sem pontuação (nunca "0 de 0").
  static ModuleScoreEntity? _scoreFromJson(Map<String, dynamic> json) {
    final int total = (json['totalScore'] as num?)?.toInt() ?? 0;
    if (total <= 0) return null;
    return ModuleScoreEntity(
      score: (json['score'] as num?)?.toInt() ?? 0,
      total: total,
    );
  }
}
