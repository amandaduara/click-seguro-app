import 'package:click_seguro_app/modules/activities/domain/entities/module_status.dart';

/// Um módulo de atividades no painel, com o progresso da pessoa. Uma lição
/// conta como concluída ao ser respondida, certa ou errada (R0 de
/// specs/015-painel-atividades).
class ModuleSummaryEntity {
  ModuleSummaryEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    this.iconUrl,
    required this.lessonsCount,
    required int completedCount,
  }) : completedCount = completedCount.clamp(0, lessonsCount);

  final String id;
  final String title;
  final String description;
  final int order;
  final String? iconUrl;
  final int lessonsCount;

  /// Limitado a `0…lessonsCount`, mesmo se o serviço mandar mais.
  final int completedCount;

  ModuleStatus get status {
    if (lessonsCount == 0) return ModuleStatus.unavailable;
    if (completedCount == 0) return ModuleStatus.notStarted;
    if (completedCount >= lessonsCount) return ModuleStatus.completed;
    return ModuleStatus.inProgress;
  }

  /// Sem lições, o módulo não abre (CB-012).
  bool get isAvailable => status != ModuleStatus.unavailable;

  /// Cópia com outro número de concluídas (painel do visitante, R3).
  ModuleSummaryEntity withCompletedCount(int value) => ModuleSummaryEntity(
    id: id,
    title: title,
    description: description,
    order: order,
    iconUrl: iconUrl,
    lessonsCount: lessonsCount,
    completedCount: value,
  );
}
