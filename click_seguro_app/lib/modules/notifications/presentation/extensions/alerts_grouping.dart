import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';

/// Grupos da tela de alertas, do mais recente ao mais antigo.
enum AlertGroup { today, yesterday, earlier }

class AlertSection {
  const AlertSection({required this.group, required this.alerts});

  final AlertGroup group;

  /// Do mais novo ao mais antigo.
  final List<AlertEntity> alerts;
}

/// Grupo de um alerta pelo **dia local** de `publishedAt` (R8 de
/// specs/011-alertas-locais). Data futura (relógio do aparelho atrasado) conta
/// como hoje.
extension AlertGroupOf on AlertEntity {
  AlertGroup groupAt(DateTime now) {
    final DateTime today = _dayOf(now);
    final DateTime day = _dayOf(publishedAt);
    if (!day.isBefore(today)) return AlertGroup.today;
    if (day == DateTime(today.year, today.month, today.day - 1)) {
      return AlertGroup.yesterday;
    }
    return AlertGroup.earlier;
  }
}

extension AlertsGrouping on List<AlertEntity> {
  /// Seções Hoje, Ontem e Anteriores, sem seção vazia.
  List<AlertSection> sections(DateTime now) {
    final List<AlertEntity> sorted = [...this]
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return [
      for (final AlertGroup group in AlertGroup.values)
        if (sorted.any((alert) => alert.groupAt(now) == group))
          AlertSection(
            group: group,
            alerts: [
              for (final alert in sorted)
                if (alert.groupAt(now) == group) alert,
            ],
          ),
    ];
  }
}

DateTime _dayOf(DateTime moment) {
  final DateTime local = moment.toLocal();
  return DateTime(local.year, local.month, local.day);
}
