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

  /// Todas as lições válidas respondidas: o fim do módulo (RN-005).
  bool get isFullyCompleted =>
      lessons.isNotEmpty && lessons.every((lesson) => lesson.isCompleted);

  /// Abrir o módulo começa uma tentativa nova quando a pessoa pede para
  /// refazer ([retake]) ou quando ele já está todo concluído: o progresso
  /// começa do zero ([forRetake]). Feito pela metade, retoma de onde parou
  /// (specs/025).
  bool startsNewAttempt({bool retake = false}) => retake || isFullyCompleted;

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
