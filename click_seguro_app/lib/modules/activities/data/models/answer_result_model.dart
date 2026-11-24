import 'package:click_seguro_app/modules/activities/domain/entities/answer_result_entity.dart';

/// `POST …/lessons/{lessonId}/answer` (contrato da API 1.0.10; R0 de
/// specs/018-resposta-feedback-atividades).
class AnswerResultModel {
  const AnswerResultModel({
    required this.isCorrect,
    required this.correctOptionId,
    this.explanation,
  });

  factory AnswerResultModel.fromJson(Map<String, dynamic> json) {
    final Object? explanation = json['explanation'];
    return AnswerResultModel(
      isCorrect: json['isCorrect'] as bool,
      correctOptionId: json['correctOptionId'] as String,
      explanation: explanation is String && explanation.isNotEmpty
          ? explanation
          : null,
    );
  }

  final bool isCorrect;
  final String correctOptionId;
  final String? explanation;

  AnswerResultEntity toEntity() => AnswerResultEntity(
    isCorrect: isCorrect,
    correctOptionId: correctOptionId,
    explanation: explanation,
  );
}
