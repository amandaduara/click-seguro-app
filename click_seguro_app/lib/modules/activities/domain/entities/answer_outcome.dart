import 'package:click_seguro_app/modules/activities/domain/entities/answer_result_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';

/// O que a tela recebe ao responder: a correção e a pontuação do módulo
/// depois dela (`null` se a busca falhou ou ainda não há, R3 de
/// specs/018-resposta-feedback-atividades).
class AnswerOutcome {
  const AnswerOutcome({required this.result, this.score});

  final AnswerResultEntity result;
  final ModuleScoreEntity? score;
}
