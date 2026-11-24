import 'package:click_seguro_app/modules/notifications/domain/entities/alerts_snapshot.dart';

/// Como terminou uma conferência que não falhou.
enum CheckOutcome {
  /// Primeira da conta neste aparelho: só marcou o horário (FR-003).
  firstRun,

  /// "Receber alertas" desligado: o horário avançou, sem alertas (FR-006).
  disabled,

  /// Conferiu o serviço, havendo ou não alertas novos.
  updated,
}

class CheckNewAlertsResult {
  const CheckNewAlertsResult({required this.snapshot, required this.outcome});

  /// Estado guardado depois da conferência.
  final AlertsSnapshot snapshot;
  final CheckOutcome outcome;
}
