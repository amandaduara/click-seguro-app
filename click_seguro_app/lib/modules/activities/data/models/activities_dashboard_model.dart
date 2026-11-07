import 'package:click_seguro_app/modules/activities/data/models/module_summary_model.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/activities_dashboard_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_summary_entity.dart';

/// `GET /app/educational/modules` (contrato da API; formato conferido no R0
/// de specs/015-painel-atividades).
class ActivitiesDashboardModel {
  const ActivitiesDashboardModel({
    required this.modules,
    required this.totalCompleted,
    required this.totalAvailable,
  });

  factory ActivitiesDashboardModel.fromJson(Map<String, dynamic> json) {
    final List<ModuleSummaryEntity> modules = [
      for (final Object? item in json['modules'] as List)
        ?ModuleSummaryModel.fromJson(item as Map<String, dynamic>),
    ]..sort((a, b) => a.order.compareTo(b.order));
    return ActivitiesDashboardModel(
      modules: modules,
      totalCompleted: (json['totalLessonsCompleted'] as num?)?.toInt() ?? 0,
      totalAvailable: (json['totalLessonsAvailable'] as num?)?.toInt() ?? 0,
    );
  }

  final List<ModuleSummaryEntity> modules;
  final int totalCompleted;
  final int totalAvailable;

  ActivitiesDashboardEntity toEntity() => ActivitiesDashboardEntity(
    modules: modules,
    totalCompleted: totalCompleted,
    totalAvailable: totalAvailable,
  );
}
