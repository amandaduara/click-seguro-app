import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/activities_dashboard_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_summary_entity.dart';

/// Dados de exemplo para o esqueleto do painel de atividades (specs/022 R8).
abstract final class ActivitiesPlaceholders {
  static ActivitiesDashboardEntity dashboard() => ActivitiesDashboardEntity(
    modules: [
      for (int index = 0; index < 4; index++)
        ModuleSummaryEntity(
          id: 'placeholder-$index',
          title: SafeSkeleton.text(2),
          description: SafeSkeleton.text(8),
          order: index,
          lessonsCount: 3,
          completedCount: 1,
        ),
    ],
    totalCompleted: 4,
    totalAvailable: 12,
  );
}
