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
}
