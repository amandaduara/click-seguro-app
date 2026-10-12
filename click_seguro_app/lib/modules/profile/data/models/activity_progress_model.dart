import 'package:click_seguro_app/modules/profile/domain/entities/activity_progress_entity.dart';

/// `GET /app/educational/modules`: só o que as conquistas usam.
class ActivityProgressModel {
  const ActivityProgressModel({
    required this.modules,
    required this.lessonsCompleted,
  });

  factory ActivityProgressModel.fromJson(Map<String, dynamic> json) =>
      ActivityProgressModel(
        modules: [
          for (final module in json['modules'] as List)
            _moduleFromJson(module as Map<String, dynamic>),
        ],
        lessonsCompleted: (json['totalLessonsCompleted'] as num).toInt(),
      );

  final List<ModuleProgressEntity> modules;
  final int lessonsCompleted;

  static ModuleProgressEntity _moduleFromJson(Map<String, dynamic> json) =>
      ModuleProgressEntity(
        title: json['title'] as String,
        order: (json['order'] as num).toInt(),
        lessonsCount: (json['lessonsCount'] as num).toInt(),
        completedCount: (json['completedCount'] as num).toInt(),
      );

  ActivityProgressEntity toEntity() => ActivityProgressEntity(
    modules: modules,
    lessonsCompleted: lessonsCompleted,
  );
}
