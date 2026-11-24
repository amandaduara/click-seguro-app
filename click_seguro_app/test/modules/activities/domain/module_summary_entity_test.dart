import 'package:click_seguro_app/modules/activities/domain/entities/activities_dashboard_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_status.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_summary_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ModuleSummaryEntity module({
    int lessons = 3,
    int completed = 0,
    ModuleScoreEntity? score,
  }) => ModuleSummaryEntity(
    id: 'm1',
    title: 'Golpes Digitais',
    description: 'Descrição',
    order: 1,
    lessonsCount: lessons,
    completedCount: completed,
    score: score,
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

  group('refazer (specs/025)', () {
    ModuleSummaryEntity finished(int score, {int total = 3}) => module(
      lessons: total,
      completed: total,
      score: ModuleScoreEntity(score: score, total: total),
    );

    test('concluído com acertos abaixo da metade → refazer', () {
      expect(finished(0).status, ModuleStatus.retry);
      expect(finished(1).status, ModuleStatus.retry);
      expect(finished(4, total: 10).status, ModuleStatus.retry);
    });

    test('metade ou mais → concluído', () {
      expect(finished(2).status, ModuleStatus.completed);
      expect(finished(3).status, ModuleStatus.completed);
      expect(finished(5, total: 10).status, ModuleStatus.completed);
    });

    test('sem pontuação → concluído', () {
      expect(module(completed: 3).status, ModuleStatus.completed);
    });

    test('em andamento, mesmo errando tudo, não é refazer', () {
      final ModuleSummaryEntity partial = module(
        completed: 2,
        score: const ModuleScoreEntity(score: 0, total: 3),
      );

      expect(partial.status, ModuleStatus.inProgress);
      expect(partial.isFinished, isFalse);
    });

    test('isFinished vale para concluído e para refazer', () {
      expect(finished(0).isFinished, isTrue);
      expect(finished(3).isFinished, isTrue);
      expect(finished(0).isAvailable, isTrue);
    });

    test('withScore e withCompletedCount preservam o resto', () {
      final ModuleSummaryEntity withScore = module(
        completed: 3,
      ).withScore(const ModuleScoreEntity(score: 1, total: 3));

      expect(withScore.status, ModuleStatus.retry);
      expect(withScore.completedCount, 3);
      expect(withScore.withCompletedCount(3).score?.score, 1);
      expect(withScore.withScore(null).status, ModuleStatus.completed);
    });

    test('ModuleScoreEntity.isMostlyWrong', () {
      expect(const ModuleScoreEntity(score: 1, total: 3).isMostlyWrong, isTrue);
      expect(
        const ModuleScoreEntity(score: 2, total: 4).isMostlyWrong,
        isFalse,
      );
      expect(
        const ModuleScoreEntity(score: 0, total: 0).isMostlyWrong,
        isFalse,
      );
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
