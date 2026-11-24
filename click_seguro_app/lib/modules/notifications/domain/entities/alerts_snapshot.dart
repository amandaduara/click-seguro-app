import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';

/// O que a conta tem guardado no aparelho: os alertas, as marcações de lido e
/// a última conferência (specs/011-alertas-locais, data-model).
class AlertsSnapshot {
  const AlertsSnapshot({
    this.lastCheckAt,
    this.receiveAlerts,
    this.alerts = const [],
  });

  /// Alertas guardados, no máximo.
  static const int maxAlerts = 50;

  /// Dias que um alerta fica guardado, contados da publicação.
  static const int retentionDays = 30;

  /// `null`: nenhuma conferência ainda (a próxima é a primeira).
  final DateTime? lastCheckAt;

  /// Último valor de "Receber alertas" visto no serviço; `null`, desconhecido.
  final bool? receiveAlerts;

  /// Do mais novo ao mais antigo, sem repetir [AlertEntity.newsId].
  final List<AlertEntity> alerts;

  AlertsSnapshot copyWith({
    DateTime? lastCheckAt,
    bool? receiveAlerts,
    List<AlertEntity>? alerts,
  }) => AlertsSnapshot(
    lastCheckAt: lastCheckAt ?? this.lastCheckAt,
    receiveAlerts: receiveAlerts ?? this.receiveAlerts,
    alerts: alerts ?? this.alerts,
  );
}

extension AlertsSnapshotOperations on AlertsSnapshot {
  int get unreadCount => alerts.where((alert) => !alert.isRead).length;

  bool get isEmpty => alerts.isEmpty;

  /// Id inexistente: devolve um registro igual, sem erro.
  AlertsSnapshot markRead(String newsId) => copyWith(
    alerts: [
      for (final alert in alerts)
        alert.newsId == newsId ? alert.copyWith(isRead: true) : alert,
    ],
  );

  AlertsSnapshot markAllRead() => copyWith(
    alerts: [for (final alert in alerts) alert.copyWith(isRead: true)],
  );

  /// Junta [candidates] aos alertas guardados (o já guardado vence, para
  /// manter o `isRead`), tira os de mais de [AlertsSnapshot.retentionDays]
  /// dias, ordena do mais novo ao mais antigo e fica com
  /// [AlertsSnapshot.maxAlerts].
  AlertsSnapshot merge(List<AlertEntity> candidates, DateTime now) {
    final limit = now.subtract(
      const Duration(days: AlertsSnapshot.retentionDays),
    );
    final byId = <String, AlertEntity>{};
    for (final alert in [...alerts, ...candidates]) {
      byId.putIfAbsent(alert.newsId, () => alert);
    }
    final kept =
        byId.values
            .where((alert) => !alert.publishedAt.isBefore(limit))
            .toList()
          ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return copyWith(alerts: kept.take(AlertsSnapshot.maxAlerts).toList());
  }
}
