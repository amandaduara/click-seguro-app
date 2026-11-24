import 'package:click_seguro_app/modules/activities/domain/entities/module_summary_entity.dart';

/// O painel: módulos na ordem do serviço e o progresso geral (RF-023).
class ActivitiesDashboardEntity {
  const ActivitiesDashboardEntity({
    required this.modules,
    required int totalCompleted,
    required this.totalAvailable,
  }) : _totalCompleted = totalCompleted;

  final List<ModuleSummaryEntity> modules;

  /// Lições de todos os módulos; o serviço já exclui os sem lições.
  final int totalAvailable;

  final int _totalCompleted;

  /// Limitado a `0…totalAvailable`.
  int get totalCompleted => _totalCompleted.clamp(0, totalAvailable);

  bool get isEmpty => modules.isEmpty;

  /// Sem lições no total não há "0 de 0" (edge case da spec).
  bool get hasOverallProgress => totalAvailable > 0;

  double get overallProgress =>
      hasOverallProgress ? totalCompleted / totalAvailable : 0;
}
