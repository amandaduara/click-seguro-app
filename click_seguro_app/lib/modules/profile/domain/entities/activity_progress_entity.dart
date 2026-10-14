/// Progresso da conta em um módulo de atividades.
class ModuleProgressEntity {
  const ModuleProgressEntity({
    required this.title,
    required this.order,
    required this.lessonsCount,
    required this.completedCount,
  });

  final String title;
  final int order;
  final int lessonsCount;
  final int completedCount;

  /// Módulo sem lições nunca conta como concluído.
  bool get isCompleted => lessonsCount > 0 && completedCount >= lessonsCount;
}

/// `GET /app/educational/modules` resumido para as conquistas (R3).
class ActivityProgressEntity {
  const ActivityProgressEntity({
    required this.modules,
    required this.lessonsCompleted,
  });

  final List<ModuleProgressEntity> modules;
  final int lessonsCompleted;

  int get modulesCompleted => modules.where((m) => m.isCompleted).length;

  int get modulesWithLessons => modules.where((m) => m.lessonsCount > 0).length;
}
