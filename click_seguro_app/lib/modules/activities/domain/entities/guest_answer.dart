/// A resposta mais recente do visitante a uma lição (R3 de
/// specs/015-painel-atividades): o que é reenviado ao criar conta. O
/// [isCorrect] dá a pontuação do visitante (R4 de specs/018).
class GuestAnswer {
  const GuestAnswer({
    required this.moduleId,
    required this.lessonId,
    required this.selectedOptionId,
    required this.isCorrect,
  });

  final String moduleId;
  final String lessonId;
  final String selectedOptionId;
  final bool isCorrect;
}
