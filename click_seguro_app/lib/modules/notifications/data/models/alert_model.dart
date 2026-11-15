import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';

/// Alerta no formato do registro local, ou lido de um item de notícia do
/// serviço (formato conferido em research R0 de specs/011-alertas-locais).
class AlertModel {
  const AlertModel({
    required this.newsId,
    required this.title,
    required this.source,
    required this.publishedAt,
    this.imageUrl,
    this.isRead = false,
  });

  /// Item de `GET /app/news`. Sem `publishedAt`, usa `originalPublishedAt`.
  /// Falta de `id`, título, fonte ou data: [FormatException] (o datasource
  /// ignora o item, R9).
  factory AlertModel.fromNewsJson(Map<String, dynamic> json) => AlertModel(
    newsId: _requiredText(json, 'id'),
    title: _requiredText(json, 'title'),
    source: _requiredText(json, 'source'),
    publishedAt: _date(json['publishedAt'] ?? json['originalPublishedAt']),
    imageUrl: _optionalText(json, 'imageUrl'),
  );

  /// Alerta do registro local (`toJson`); item ilegível lança
  /// [FormatException].
  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
    newsId: _requiredText(json, 'newsId'),
    title: _requiredText(json, 'title'),
    source: _requiredText(json, 'source'),
    publishedAt: _date(json['publishedAt']),
    imageUrl: _optionalText(json, 'imageUrl'),
    isRead: json['isRead'] == true,
  );

  factory AlertModel.fromEntity(AlertEntity entity) => AlertModel(
    newsId: entity.newsId,
    title: entity.title,
    source: entity.source,
    publishedAt: entity.publishedAt.toUtc(),
    imageUrl: entity.imageUrl,
    isRead: entity.isRead,
  );

  final String newsId;
  final String title;
  final String source;
  final DateTime publishedAt;
  final String? imageUrl;
  final bool isRead;

  Map<String, dynamic> toJson() => {
    'newsId': newsId,
    'title': title,
    'source': source,
    'publishedAt': publishedAt.toIso8601String(),
    'imageUrl': ?imageUrl,
    'isRead': isRead,
  };

  AlertEntity toEntity() => AlertEntity(
    newsId: newsId,
    title: title,
    source: source,
    publishedAt: publishedAt,
    imageUrl: imageUrl,
    isRead: isRead,
  );

  /// Texto opcional: ausente, vazio ou de outro tipo vira `null`.
  static String? _optionalText(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  static String _requiredText(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Campo "$key" ausente ou vazio');
    }
    return value;
  }

  static DateTime _date(Object? value) {
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed == null) throw const FormatException('Data ausente ou ilegível');
    return parsed.toUtc();
  }
}
