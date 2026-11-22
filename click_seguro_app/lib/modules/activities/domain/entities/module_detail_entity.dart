import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';

/// Um módulo com as suas lições válidas, na ordem do serviço (RF-024). O id
/// fica na rota (`/activities/:moduleId`).
class ModuleDetailEntity {
  const ModuleDetailEntity({
    required this.title,
    required this.lessons,
    this.score,
  });

  final String title;
  final List<LessonEntity> lessons;

  /// `null` enquanto não há pontuação (RN-005).
  final ModuleScoreEntity? score;

  bool get isEmpty => lessons.isEmpty;

  /// Uma nova tentativa (refazer): as respostas antigas do serviço não contam
  /// no progresso; só as lições em [answeredInAttempt] (respondidas nesta
  /// tentativa) ficam concluídas. A pontuação continua a do serviço até a
  /// primeira resposta nova (specs/025).
  ModuleDetailEntity forRetake({Set<String> answeredInAttempt = const {}}) =>
      ModuleDetailEntity(
        title: title,
        lessons: [
          for (final LessonEntity lesson in lessons)
            lesson.withCompleted(answeredInAttempt.contains(lesson.id)),
        ],
        score: score,
      );
}
