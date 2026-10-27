import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';

class AiAnalysisModel {
  const AiAnalysisModel(this.entity);

  factory AiAnalysisModel.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String?;
    return AiAnalysisModel(
      AiAnalysisEntity(
        id: json['id'] as String,
        feature: _feature(json['feature'] as String),
        threatType: rawType == null ? null : _threat(rawType),
        riskScore: (json['riskScore'] as num?)?.toDouble(),
        confidence: (json['confidence'] as num?)?.toDouble(),
        explanation: json['explanation'] as String?,
        tips: (json['tips'] as List).cast<String>(),
        status: _status(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      ),
    );
  }

  final AiAnalysisEntity entity;

  static AiAnalysisFeature _feature(String value) => switch (value) {
    'ANALYZE' => AiAnalysisFeature.analyze,
    'CHAT' => AiAnalysisFeature.chat,
    _ => AiAnalysisFeature.unknown,
  };

  static AiThreatType _threat(String value) => switch (value) {
    'PHISHING' => AiThreatType.phishing,
    'FAKE_NEWS' => AiThreatType.fakeNews,
    'FINANCIAL_SCAM' => AiThreatType.financialScam,
    'SOCIAL_ENGINEERING' => AiThreatType.socialEngineering,
    'SPAM' => AiThreatType.spam,
    'SAFE' => AiThreatType.safe,
    'UNCERTAIN' => AiThreatType.uncertain,
    _ => AiThreatType.unknown,
  };

  static AiAnalysisStatus _status(String value) => switch (value) {
    'SUCCESS' => AiAnalysisStatus.success,
    'ERROR' => AiAnalysisStatus.error,
    'RATE_LIMITED' => AiAnalysisStatus.rateLimited,
    _ => AiAnalysisStatus.unknown,
  };
}
