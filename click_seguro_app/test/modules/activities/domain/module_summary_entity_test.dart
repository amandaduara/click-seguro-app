import 'package:click_seguro_app/modules/activities/domain/entities/activities_dashboard_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_status.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_summary_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ModuleSummaryEntity module({int lessons = 3, int completed = 0}) =>
      ModuleSummaryEntity(
        id: 'm1',
        title: 'Golpes Digitais',
        description: 'Descrição',
        order: 1,
        lessonsCount: lessons,
        completedCount: completed,
      );

  group('status (R2)', () {
    test('sem lições → indisponível, mesmo com concluídas', () {
      expect(module(lessons: 0).status, ModuleStatus.unavailable);
      expect(module(lessons: 0, completed: 2).status, ModuleStatus.unavailable);
      expect(module(lessons: 0).isAvailable, isFalse);
    });

    test('nenhuma concluída → não iniciado', () {
      expect(module().status, ModuleStatus.notStarted);
      expect(module().isAvailable, isTrue);
    });

    test('parte concluída → em andamento', () {
      expect(module(completed: 1).status, ModuleStatus.inProgress);
      expect(module(completed: 2).status, ModuleStatus.inProgress);
    });

    test('todas concluídas → concluído', () {
      expect(module(completed: 3).status, ModuleStatus.completed);
    });
  });

  test('concluídas acima do total ficam no total (dado inconsistente)', () {
    final ModuleSummaryEntity entity = module(completed: 5);

    expect(entity.completedCount, 3);
    expect(entity.status, ModuleStatus.completed);
  });

  test('concluídas negativas viram 0', () {
    expect(module(completed: -1).completedCount, 0);
  });

  test('progresso: 0 sem lições, fração com lições', () {
    expect(module(lessons: 0).progress, 0);
    expect(module(completed: 2).progress, closeTo(2 / 3, 0.0001));
  });

  test('withCompletedCount devolve cópia com o novo número', () {
    final ModuleSummaryEntity original = module();
    final ModuleSummaryEntity copy = original.withCompletedCount(2);

    expect(copy.completedCount, 2);
    expect(copy.id, original.id);
    expect(original.completedCount, 0);
    expect(module().withCompletedCount(9).completedCount, 3);
  });

  group('ActivitiesDashboardEntity', () {
    test('vazio e sem progresso geral', () {
      const dashboard = ActivitiesDashboardEntity(
        modules: [],
        totalCompleted: 0,
        totalAvailable: 0,
      );

      expect(dashboard.isEmpty, isTrue);
      expect(dashboard.hasOverallProgress, isFalse);
      expect(dashboard.overallProgress, 0);
    });

    test('progresso geral e total concluído limitado', () {
      final dashboard = ActivitiesDashboardEntity(
        modules: [module()],
        totalCompleted: 4,
        totalAvailable: 9,
      );
      final over = ActivitiesDashboardEntity(
        modules: [module()],
        totalCompleted: 12,
        totalAvailable: 9,
      );

      expect(dashboard.isEmpty, isFalse);
      expect(dashboard.hasOverallProgress, isTrue);
      expect(dashboard.overallProgress, closeTo(4 / 9, 0.0001));
      expect(over.totalCompleted, 9);
    });
  });
}
