/// A pontuação do módulo (RN-005): acertos na resposta mais recente de cada
/// lição. Só existe com [total] > 0, para nunca mostrar "0 de 0" (FR-011).
class ModuleScoreEntity {
  const ModuleScoreEntity({required this.score, required this.total});

  final int score;
  final int total;

  /// Acertou menos da metade: errou a maioria (specs/025). Metade ou mais
  /// não conta, como na mensagem da conclusão.
  bool get isMostlyWrong => total > 0 && score * 2 < total;
}
