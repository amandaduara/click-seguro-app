import 'package:click_seguro_app/modules/notifications/data/models/alert_model.dart';

abstract class AlertsRemoteDataSource {
  /// Notícias publicadas a partir de [since], da mais nova para a mais
  /// antiga, no máximo [limit]. Item inválido é ignorado; corpo sem `data`
  /// como lista lança `ApiException` de resposta inválida.
  Future<List<AlertModel>> fetchNewAlerts({
    required DateTime since,
    required int limit,
  });

  /// `receiveNotifications` de `GET /users/me`; ausente, `true`.
  Future<bool> getReceiveAlerts();
}
