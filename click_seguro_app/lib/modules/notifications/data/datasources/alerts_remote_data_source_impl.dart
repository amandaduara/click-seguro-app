import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/notifications/data/datasources/alerts_remote_data_source.dart';
import 'package:click_seguro_app/modules/notifications/data/models/alert_model.dart';

/// Datasource próprio: não importa o módulo `news` (specs/011, R1 e plano).
class AlertsRemoteDataSourceImpl implements AlertsRemoteDataSource {
  AlertsRemoteDataSourceImpl(this._apiClient);

  static const String newsPath = '/app/news';
  static const String mePath = '/users/me';

  /// Igual ao teto de alertas (R6 de specs/011).
  static const int checkLimit = 50;

  final ApiClient _apiClient;

  @override
  Future<List<AlertModel>> fetchNewAlerts({
    required DateTime since,
    required int limit,
  }) async {
    final response = await _apiClient.get(
      newsPath,
      queryParameters: {
        'startDate': since.toUtc().toIso8601String(),
        'sortBy': 'publishedAt',
        'sortOrder': 'desc',
        'limit': limit,
        'page': 1,
      },
    );
    return response.toModel((json) {
      final items = json['data'] as List;
      return [for (final item in items) ?_tryAlert(item)];
    });
  }

  @override
  Future<bool> getReceiveAlerts() async {
    final response = await _apiClient.get(mePath);
    return response.toModel(
      (json) => json['receiveNotifications'] as bool? ?? true,
    );
  }

  AlertModel? _tryAlert(Object? item) {
    if (item is! Map<String, dynamic>) return null;
    try {
      return AlertModel.fromNewsJson(item);
    } on FormatException {
      return null;
    }
  }
}
