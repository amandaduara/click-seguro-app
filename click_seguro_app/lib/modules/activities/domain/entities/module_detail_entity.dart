import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';

/// Um módulo com as suas lições válidas, na ordem do serviço (RF-024). O id
/// fica na rota (`/activities/:moduleId`).
class ModuleDetailEntity {
  const ModuleDetailEntity({required this.title, required this.lessons});

  final String title;
  final List<LessonEntity> lessons;

  bool get isEmpty => lessons.isEmpty;
}
