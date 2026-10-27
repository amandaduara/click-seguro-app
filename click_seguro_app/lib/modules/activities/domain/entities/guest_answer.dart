/// A resposta mais recente do visitante a uma lição (R3 de
/// specs/015-painel-atividades): o que é reenviado ao criar conta.
class GuestAnswer {
  const GuestAnswer({
    required this.moduleId,
    required this.lessonId,
    required this.selectedOptionId,
  });

  final String moduleId;
  final String lessonId;
  final String selectedOptionId;
}
