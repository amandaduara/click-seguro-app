enum AiThreatType {
  phishing,
  fakeNews,
  financialScam,
  socialEngineering,
  spam,
  safe,
  uncertain,
  unknown,
}

enum AiAnalysisFeature { analyze, chat, unknown }

enum AiInputType { text, image, unknown }

enum AiAnalysisStatus { success, error, rateLimited, unknown }

class AiAnalysisEntity {
  const AiAnalysisEntity({
    required this.id,
    required this.feature,
    required this.threatType,
    required this.riskScore,
    required this.confidence,
    required this.explanation,
    required this.tips,
    required this.cached,
    required this.inputType,
    required this.source,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final AiAnalysisFeature feature;
  final AiThreatType? threatType;
  final double? riskScore;
  final double? confidence;
  final String? explanation;
  final List<String> tips;
  final bool cached;
  final AiInputType inputType;
  final String? source;
  final AiAnalysisStatus status;
  final DateTime createdAt;
}
