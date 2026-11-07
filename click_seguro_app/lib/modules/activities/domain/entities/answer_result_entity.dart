/// O resultado da correção de uma resposta, feita pelo serviço (RF-026).
class AnswerResultEntity {
  const AnswerResultEntity({
    required this.isCorrect,
    required this.correctOptionId,
    this.explanation,
  });

  final bool isCorrect;
  final String correctOptionId;

  /// Por que a correta é a correta; nem toda lição tem.
  final String? explanation;
}
