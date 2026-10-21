Map<String, Object?> aiAnalysisJson({
  Object? type = 'PHISHING',
  Object? riskScore = 92,
  Object? confidence = 81,
  String inputType = 'TEXT',
  String status = 'SUCCESS',
}) => {
  'id': 'analysis-1',
  'feature': 'ANALYZE',
  'type': type,
  'riskScore': riskScore,
  'confidence': confidence,
  'explanation': 'Verifique o remetente.',
  'tips': ['Não clique no link'],
  'cached': true,
  'inputType': inputType,
  'source': 'WHATSAPP',
  'status': status,
  'createdAt': '2026-10-20T12:00:00.000Z',
};

Map<String, Object?> aiHistoryJson({bool hasNextPage = true}) => {
  'data': [aiAnalysisJson()],
  'meta': {
    'page': 2,
    'limit': 10,
    'total': 11,
    'totalPages': 2,
    'hasNextPage': hasNextPage,
    'hasPreviousPage': true,
  },
};
