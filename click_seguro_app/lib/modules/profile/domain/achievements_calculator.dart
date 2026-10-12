import 'package:click_seguro_app/modules/profile/domain/entities/achievement_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/activity_progress_entity.dart';

/// Conquistas da conta (RN-008, R3 de specs/012-perfil), calculadas no
/// aparelho a partir das notícias lidas e do progresso nas atividades.
abstract final class AchievementsCalculator {
  static const int dedicatedStudentLessons = 10;
  static const int dedicatedReaderNews = 10;

  /// Lista completa, já na ordem de exibição: alcançadas primeiro; depois
  /// maior progresso; empate pela ordem de [AchievementKind] e, entre
  /// módulos, pelo `order` do serviço.
  static List<AchievementEntity> build({
    required int readCount,
    required ActivityProgressEntity progress,
  }) {
    final int lessons = progress.lessonsCompleted;
    final int modules = progress.modulesCompleted;
    final List<AchievementEntity> achievements = [
      AchievementEntity(
        kind: AchievementKind.firstLesson,
        current: lessons,
        target: 1,
      ),
      AchievementEntity(
        kind: AchievementKind.firstModule,
        current: modules,
        target: 1,
      ),
      AchievementEntity(
        kind: AchievementKind.dedicatedStudent,
        current: lessons,
        target: dedicatedStudentLessons,
      ),
      if (progress.modulesWithLessons > 0)
        AchievementEntity(
          kind: AchievementKind.securityMaster,
          current: modules,
          target: progress.modulesWithLessons,
        ),
      AchievementEntity(
        kind: AchievementKind.attentiveReader,
        current: readCount,
        target: 1,
      ),
      AchievementEntity(
        kind: AchievementKind.dedicatedReader,
        current: readCount,
        target: dedicatedReaderNews,
      ),
      for (final module in progress.modules)
        if (module.lessonsCount > 0)
          AchievementEntity(
            kind: AchievementKind.module,
            moduleId: module.id,
            moduleTitle: module.title,
            moduleOrder: module.order,
            current: module.completedCount,
            target: module.lessonsCount,
          ),
    ];
    return achievements..sort(_compare);
  }

  static int _compare(AchievementEntity a, AchievementEntity b) {
    if (a.achieved != b.achieved) return a.achieved ? -1 : 1;
    final int byProgress = b.progress.compareTo(a.progress);
    if (byProgress != 0) return byProgress;
    final int byKind = a.kind.index.compareTo(b.kind.index);
    if (byKind != 0) return byKind;
    return (a.moduleOrder ?? 0).compareTo(b.moduleOrder ?? 0);
  }
}
