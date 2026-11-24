import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/activities/data/models/answer_result_model.dart';
import 'package:click_seguro_app/modules/activities/data/models/module_detail_model.dart';
import 'package:click_seguro_app/modules/activities/domain/usecases/answer_lesson_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../fakes/activities_fixtures.dart';
import '../../fakes/fake_activities_repository.dart';

/// Resposta e, em seguida, só a pontuação do módulo (R3 de
/// specs/018-resposta-feedback-atividades).
void main() {
  late FakeActivitiesRepository repository;
  late AnswerLessonUseCase answerLesson;

  setUp(() {
    repository = FakeActivitiesRepository();
    answerLesson = AnswerLessonUseCase(repository);
  });

  Future<Either<Failure, dynamic>> answer() =>
      answerLesson(moduleId: 'm1', lessonId: 'l1', selectedOptionId: 'l1-o2');

  test('resultado da resposta e a pontuação recarregada', () async {
    repository
      ..answerResults = [
        Right(
          AnswerResultModel.fromJson(answerJson(isCorrect: false)).toEntity(),
        ),
      ]
      ..moduleDetailResults = [
        Right(
          ModuleDetailModel.fromJson(
            moduleDetailJson(score: 1, totalScore: 3),
          ).toEntity(),
        ),
      ];

    final outcome = (await answerLesson(
      moduleId: 'm1',
      lessonId: 'l1',
      selectedOptionId: 'l1-o2',
    )).getOrElse((failure) => throw StateError('falhou: $failure'));

    expect(repository.answerCalls.single, (
      moduleId: 'm1',
      lessonId: 'l1',
      selectedOptionId: 'l1-o2',
    ));
    expect(outcome.result.isCorrect, isFalse);
    expect(outcome.score?.score, 1);
    expect(outcome.score?.total, 3);
    expect(repository.moduleDetailCalls, 1);
  });

  test('a pontuação que falha não derruba o resultado', () async {
    repository.moduleDetailResults = [const Left(ConnectionFailure())];

    final result = await answer();

    final outcome = result.getOrElse((_) => throw StateError('falhou'));
    expect(outcome.result.isCorrect, isTrue);
    expect(outcome.score, isNull);
  });

  test('a resposta que falha volta a falha e não busca a pontuação', () async {
    repository.answerResults = [const Left(ConnectionFailure())];

    final result = await answer();

    expect(result.getLeft().toNullable(), isA<ConnectionFailure>());
    expect(repository.moduleDetailCalls, 0);
  });
}
