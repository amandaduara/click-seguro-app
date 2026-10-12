import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';
import 'package:click_seguro_app/modules/notifications/presentation/extensions/alerts_grouping.dart';
import 'package:easy_localization/easy_localization.dart';

/// Textos de um alerta na tela. Hora e data sem `intl`: 24 h e dd/MM bastam
/// (R8 de specs/011-alertas-locais).
extension AlertPresentation on AlertEntity {
  /// `HH:mm` para hoje e ontem; `dd/MM` para anteriores.
  String timeLabel(DateTime now) {
    final DateTime local = publishedAt.toLocal();
    if (groupAt(now) == AlertGroup.earlier) {
      return '${_two(local.day)}/${_two(local.month)}';
    }
    return '${_two(local.hour)}:${_two(local.minute)}';
  }

  /// "Novo, título, fonte, hora"; lido, sem o "Novo".
  String semanticLabel(DateTime now) {
    final String text = '$title, $source, ${timeLabel(now)}';
    return isRead ? text : AppStrings.notificationsSemanticNew.tr(args: [text]);
  }
}

/// Resumo fixo do alto da tela: "Você tem 3 alertas novos".
String summaryText(int unreadCount) => switch (unreadCount) {
  0 => AppStrings.notificationsSummaryNone.tr(),
  1 => AppStrings.notificationsSummaryOne.tr(),
  _ => AppStrings.notificationsSummaryMany.tr(args: ['$unreadCount']),
};

String _two(int value) => value.toString().padLeft(2, '0');
