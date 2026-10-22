import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';

/// Um módulo com as suas lições válidas, na ordem do serviço (RF-024).
class ModuleDetailEntity {
  const ModuleDetailEntity({
    required this.id,
    required this.title,
    required this.lessons,
  });

  final String id;
  final String title;
  final List<LessonEntity> lessons;

  bool get isEmpty => lessons.isEmpty;
}
