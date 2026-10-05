/// JSON no formato real do servidor (conferido em 2026-10-05, research R0
/// de specs/006-feed-inicio).
library;

const Map<String, dynamic> phishingJson = {
  'id': 'c-phishing',
  'name': 'Phishing',
  'slug': 'phishing',
};

const Map<String, dynamic> bankJson = {
  'id': 'c-bank',
  'name': 'Golpes bancários',
  'slug': 'golpes-bancarios',
};

Map<String, dynamic> newsItemJson({
  required String id,
  String title = 'Golpe do Pix',
  DateTime? originalPublishedAt,
  List<Map<String, dynamic>> categories = const [phishingJson],
  String? imageUrl = 'https://img.test/n.jpg',
  bool isRead = false,
  bool isSaved = false,
}) => {
  'id': id,
  'title': title,
  'source': 'Folha de Teste',
  'sourceUrl': 'https://fonte.test/$id',
  'isHighlight': false,
  'imageUrl': ?imageUrl,
  'publishedAt': '2026-10-05T12:00:00.000Z',
  'originalPublishedAt': (originalPublishedAt ?? DateTime.utc(2026, 9, 29, 3))
      .toIso8601String(),
  'createdAt': '2026-10-01T10:00:00.000Z',
  'categories': categories,
  'interaction': {'isLiked': false, 'isSaved': isSaved, 'isRead': isRead},
};

Map<String, dynamic> reelItemJson({required String id, String? imageUrl}) => {
  ...newsItemJson(id: id, imageUrl: imageUrl ?? 'https://img.test/r.jpg'),
  'content': 'Texto completo da notícia $id.',
  'likesCount': 3,
};

Map<String, dynamic> feedJson({
  List<Map<String, dynamic>> highlights = const [],
  List<Map<String, dynamic>> recommended = const [],
  List<Map<String, dynamic>> recent = const [],
  String? nextCursor,
}) => {
  'highlights': highlights,
  'recommended': recommended,
  'recent': {'data': recent, 'nextCursor': nextCursor},
};

Map<String, dynamic> reelsJson({
  List<Map<String, dynamic>> items = const [],
  String? nextCursor,
}) => {'data': items, 'nextCursor': nextCursor};

Map<String, dynamic> newsListJson({
  List<Map<String, dynamic>> items = const [],
  int page = 1,
  bool hasNextPage = false,
}) => {
  'data': items,
  'meta': {
    'page': page,
    'limit': 20,
    'total': items.length,
    'totalPages': hasNextPage ? page + 1 : page,
    'hasNextPage': hasNextPage,
    'hasPreviousPage': page > 1,
  },
};

/// Duas ativas e uma inativa.
const List<Map<String, dynamic>> categoriesJson = [
  {
    'id': 'c-phishing',
    'name': 'Phishing',
    'slug': 'phishing',
    'description': null,
    'isActive': true,
    'createdAt': '2026-05-26T23:21:55.746Z',
  },
  {
    'id': 'c-bank',
    'name': 'Golpes bancários',
    'slug': 'golpes-bancarios',
    'description': 'Golpes com bancos',
    'isActive': true,
    'createdAt': '2026-06-12T19:38:13.800Z',
  },
  {
    'id': 'c-old',
    'name': 'Antiga',
    'slug': 'antiga',
    'description': null,
    'isActive': false,
    'createdAt': '2026-01-01T00:00:00.000Z',
  },
];

/// [count] notícias `n<start>`…, para páginas cheias.
List<Map<String, dynamic>> newsItemsJson(int count, {int start = 1}) => [
  for (var i = start; i < start + count; i++) newsItemJson(id: 'n$i'),
];
