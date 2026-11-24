import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';
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
    this.score,
  }) : completedCount = completedCount.clamp(0, lessonsCount);

  final String id;
  final String title;
  final String description;
  final int order;
  final String? iconUrl;
  final int lessonsCount;

  /// Limitado a `0…lessonsCount`, mesmo se o serviço mandar mais.
  final int completedCount;

  /// Acertos do módulo (resposta mais recente de cada lição); `null` quando
  /// não se sabe (specs/025).
  final ModuleScoreEntity? score;

  /// Concluído errando a maioria (acertos < 50%) → refazer; sem pontuação,
  /// fica concluído (specs/025).
  ModuleStatus get status {
    if (lessonsCount == 0) return ModuleStatus.unavailable;
    if (completedCount == 0) return ModuleStatus.notStarted;
    if (completedCount < lessonsCount) return ModuleStatus.inProgress;
    return score?.isMostlyWrong ?? false
        ? ModuleStatus.retry
        : ModuleStatus.completed;
  }

  /// Todas as lições respondidas, com acertos ou não ([ModuleStatus.completed]
  /// ou [ModuleStatus.retry]).
  bool get isFinished =>
      status == ModuleStatus.completed || status == ModuleStatus.retry;

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
    score: score,
  );

  /// Cópia com outra pontuação (detalhe do módulo ou registro do visitante).
  ModuleSummaryEntity withScore(ModuleScoreEntity? value) =>
      ModuleSummaryEntity(
        id: id,
        title: title,
        description: description,
        order: order,
        iconUrl: iconUrl,
        lessonsCount: lessonsCount,
        completedCount: completedCount,
        score: value,
      );
}
