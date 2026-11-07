import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/answer_outcome.dart';
import 'package:click_seguro_app/modules/activities/domain/repositories/activities_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Responde e, se deu certo, busca a pontuação do módulo de novo (RF-028).
/// Do detalhe só o `score` serve: cada busca embaralha as alternativas, e a
/// tela não pode trocar as lições (R3 de specs/018-resposta-feedback-atividades).
class AnswerLessonUseCase {
  const AnswerLessonUseCase(this._repository);

  final ActivitiesRepository _repository;

  Future<Either<Failure, AnswerOutcome>> call({
    required String moduleId,
    required String lessonId,
    required String selectedOptionId,
  }) async {
    final answer = await _repository.answerLesson(
      moduleId: moduleId,
      lessonId: lessonId,
      selectedOptionId: selectedOptionId,
    );
    return switch (answer) {
      Left(:final value) => Left(value),
      Right(value: final result) => Right(
        AnswerOutcome(
          result: result,
          // Pontuação que não veio não esconde o resultado (FR-009).
          score: (await _repository.getModuleDetail(
            moduleId,
          )).toNullable()?.score,
        ),
      ),
    };
  }
}
