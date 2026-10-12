/// Tipos de conquista, na ordem de desempate (RN-008, R3 de specs/012-perfil).
enum AchievementKind {
  firstLesson,
  firstModule,
  dedicatedStudent,
  securityMaster,
  attentiveReader,
  dedicatedReader,
  module,
}

/// Uma medalha: alcançada ou com o progresso até ela.
class AchievementEntity {
  const AchievementEntity({
    required this.kind,
    required this.current,
    required this.target,
    this.moduleId,
    this.moduleTitle,
    this.moduleOrder,
  });

  final AchievementKind kind;

  /// Só em [AchievementKind.module].
  final String? moduleId;
  final String? moduleTitle;

  /// `order` do módulo no serviço: desempate e cor da medalha.
  final int? moduleOrder;

  final int current;
  final int target;

  bool get achieved => current >= target;

  /// De 0 a 1.
  double get progress => target <= 0 ? 0 : (current / target).clamp(0, 1);
}
