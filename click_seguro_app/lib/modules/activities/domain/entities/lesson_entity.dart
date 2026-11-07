/// Uma alternativa de uma pergunta, na ordem em que o serviço a enviou
/// (RF-027).
class LessonOptionEntity {
  const LessonOptionEntity({required this.id, required this.text});

  final String id;
  final String text;
}

/// Uma lição: uma pergunta de múltipla escolha (RF-024, RF-025). A
/// explicação e a resposta certa ficam para a B3 (R2 de
/// specs/017-perguntas-atividades).
class LessonEntity {
  const LessonEntity({
    required this.id,
    required this.order,
    required this.question,
    this.imageUrl,
    required this.options,
    required this.isCompleted,
  });

  final String id;
  final int order;
  final String question;
  final String? imageUrl;

  /// Sempre duas ou mais (CB-012).
  final List<LessonOptionEntity> options;

  /// Respondida (certa ou errada), como no serviço.
  final bool isCompleted;

  /// Cópia com outro [isCompleted] (sem conta: vem do registro da sessão, R3).
  LessonEntity withCompleted(bool value) => LessonEntity(
    id: id,
    order: order,
    question: question,
    imageUrl: imageUrl,
    options: options,
    isCompleted: value,
  );
}
