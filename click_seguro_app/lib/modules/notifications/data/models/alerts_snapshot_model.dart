import 'package:click_seguro_app/modules/notifications/data/models/alert_model.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alerts_snapshot.dart';

/// Registro local dos alertas, sem o dono (quem grava e lê o dono é o
/// datasource).
class AlertsSnapshotModel {
  const AlertsSnapshotModel({
    this.lastCheckAt,
    this.receiveAlerts,
    this.alerts = const [],
  });

  /// Tolerante: horário ou chave ausentes viram `null`, `alerts` ausente fica
  /// vazio e item ilegível é descartado.
  factory AlertsSnapshotModel.fromJson(Map<String, dynamic> json) {
    final lastCheck = json['lastCheckAt'];
    final receive = json['receiveAlerts'];
    final items = json['alerts'];
    return AlertsSnapshotModel(
      lastCheckAt: lastCheck is String
          ? DateTime.tryParse(lastCheck)?.toUtc()
          : null,
      receiveAlerts: receive is bool ? receive : null,
      alerts: [
        if (items is List)
          for (final item in items) ?_tryAlert(item),
      ],
    );
  }

  factory AlertsSnapshotModel.fromEntity(AlertsSnapshot snapshot) =>
      AlertsSnapshotModel(
        lastCheckAt: snapshot.lastCheckAt?.toUtc(),
        receiveAlerts: snapshot.receiveAlerts,
        alerts: [
          for (final alert in snapshot.alerts) AlertModel.fromEntity(alert),
        ],
      );

  final DateTime? lastCheckAt;
  final bool? receiveAlerts;
  final List<AlertModel> alerts;

  Map<String, dynamic> toJson() => {
    'lastCheckAt': lastCheckAt?.toIso8601String(),
    'receiveAlerts': receiveAlerts,
    'alerts': [for (final alert in alerts) alert.toJson()],
  };

  AlertsSnapshot toEntity() => AlertsSnapshot(
    lastCheckAt: lastCheckAt,
    receiveAlerts: receiveAlerts,
    alerts: [for (final alert in alerts) alert.toEntity()],
  );

  static AlertModel? _tryAlert(Object? item) {
    if (item is! Map<String, dynamic>) return null;
    try {
      return AlertModel.fromJson(item);
    } on FormatException {
      return null;
    }
  }
}
