import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';

/// Dados de exemplo para o esqueleto da lista de alertas (specs/022 R8).
abstract final class AlertPlaceholders {
  static List<AlertEntity> alerts(DateTime now) => [
    for (int index = 0; index < 4; index++)
      AlertEntity(
        newsId: 'placeholder-$index',
        title: SafeSkeleton.text(8),
        source: SafeSkeleton.text(1),
        publishedAt: now,
      ),
  ];
}
