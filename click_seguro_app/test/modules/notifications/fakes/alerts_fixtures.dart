/// JSON no formato real do servidor (conferido em 2026-10-09, research R0 de
/// specs/011-alertas-locais) e construtores de alertas e registros de teste.
library;

import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alerts_snapshot.dart';

/// "Agora" dos testes.
final DateTime testNow = DateTime.utc(2026, 10, 9, 15);

/// Item real de `GET /app/news` (`publishedAt` e `originalPublishedAt`
/// distintos).
const Map<String, dynamic> realBankNewsJson = {
  'id': 'cmuywjppz0001fo1slem3p1zr',
  'title': 'Banco não pede senha, token ou código por telefone',
  'source': 'Banco Central do Brasil',
  'sourceUrl': 'https://www.bcb.gov.br/',
  'isHighlight': false,
  'imageUrl':
      'https://res.cloudinary.com/dscx04iyv/image/upload/f_auto,q_auto/v1/clickseguro_prod/news/news_cmuywjppz0001fo1slem3p1zr?_a=BAMAOGiu0',
  'publishedAt': '2026-10-08T02:16:03.253Z',
  'originalPublishedAt': '2026-09-27T00:13:16.345Z',
  'createdAt': '2026-10-08T02:13:17.687Z',
  'categories': [
    {
      'id': 'cmqbbwzoo0002fp1rvr49w66h',
      'name': 'Segurança Bancária',
      'slug': 'seguranca-bancaria',
    },
  ],
  'interaction': {'isLiked': false, 'isSaved': false, 'isRead': false},
};

const Map<String, dynamic> realPixNewsJson = {
  'id': 'cmuywmr7p000nfo1sucepkjy5',
  'title':
      'Golpe do PIX "em dobro": promessa de devolver o dobro do valor é sempre falsa',
  'source': 'Banco Central do Brasil',
  'sourceUrl': 'https://www.bcb.gov.br/estabilidadefinanceira/pix',
  'isHighlight': true,
  'imageUrl':
      'https://res.cloudinary.com/dscx04iyv/image/upload/f_auto,q_auto/v1/clickseguro_prod/news/news_cmuywmr7p000nfo1sucepkjy5?_a=BAMAOGiu0',
  'publishedAt': '2026-10-08T02:15:44.732Z',
  'originalPublishedAt': '2026-10-08T00:14:29.869Z',
  'createdAt': '2026-10-08T02:15:39.590Z',
  'categories': [
    {
      'id': 'cmpn9f6si0000f91suoip7ctg',
      'name': 'Golpes Digitais',
      'slug': 'golpes-digitais',
    },
  ],
  'interaction': {'isLiked': false, 'isSaved': false, 'isRead': false},
};

/// Item de notícia; [publishedAt] `null` omite o campo.
Map<String, dynamic> newsItemJson({
  required String id,
  String title = 'Golpe do Pix',
  String source = 'Folha de Teste',
  String? publishedAt = '2026-10-09T14:00:00.000Z',
  String originalPublishedAt = '2026-09-29T03:00:00.000Z',
}) => {
  'id': id,
  'title': title,
  'source': source,
  'sourceUrl': 'https://fonte.test/$id',
  'isHighlight': false,
  'publishedAt': ?publishedAt,
  'originalPublishedAt': originalPublishedAt,
  'createdAt': '2026-10-01T10:00:00.000Z',
  'categories': <Object>[],
  'interaction': {'isLiked': false, 'isSaved': false, 'isRead': false},
};

/// `{data, meta}` de `GET /app/news`.
Map<String, dynamic> newsListJson(List<Map<String, dynamic>> items) => {
  'data': items,
  'meta': {
    'page': 1,
    'limit': 50,
    'total': items.length,
    'totalPages': 1,
    'hasNextPage': false,
    'hasPreviousPage': false,
  },
};

/// `GET /users/me`; [receiveNotifications] `null` omite o campo.
Map<String, dynamic> profileJson({bool? receiveNotifications}) => {
  'name': 'Maria Teste',
  'email': 'maria@example.com',
  'phone': null,
  'avatarUrl': null,
  'role': 'USER',
  'receiveNotifications': ?receiveNotifications,
};

/// Alerta de teste; sem [publishedAt], uma hora antes de [testNow].
AlertEntity alert({
  String newsId = 'n1',
  String title = 'Golpe do Pix',
  String source = 'Folha de Teste',
  DateTime? publishedAt,
  bool isRead = false,
}) => AlertEntity(
  newsId: newsId,
  title: title,
  source: source,
  publishedAt: publishedAt ?? testNow.subtract(const Duration(hours: 1)),
  isRead: isRead,
);

/// Registro de teste; sem [lastCheckAt], uma hora antes de [testNow].
AlertsSnapshot snapshot({
  DateTime? lastCheckAt,
  bool? receiveAlerts,
  List<AlertEntity> alerts = const [],
}) => AlertsSnapshot(
  lastCheckAt: lastCheckAt ?? testNow.subtract(const Duration(hours: 1)),
  receiveAlerts: receiveAlerts,
  alerts: alerts,
);
