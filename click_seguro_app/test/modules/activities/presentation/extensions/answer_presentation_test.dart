import 'package:click_seguro_app/modules/activities/data/models/answer_result_model.dart';
import 'package:click_seguro_app/modules/activities/data/models/module_detail_model.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/answer_result_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/extensions/answer_presentation.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/lesson_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/localized_app.dart';
import '../../fakes/activities_fixtures.dart';

void main() {
  final LessonEntity lesson = ModuleDetailModel.fromJson(
    moduleDetailJson(),
  ).toEntity().lessons.first;

  AnswerResultEntity result({
    bool isCorrect = true,
    String correctOptionId = 'l1-o1',
    String? explanation = 'Promessas de dinheiro em dobro são golpe.',
  }) => AnswerResultModel.fromJson(
    answerJson(
      isCorrect: isCorrect,
      correctOptionId: correctOptionId,
      explanation: explanation,
    ),
  ).toEntity();

  group('texto falado do feedback (US5)', () {
    testWidgets('resultado, correta, explicação e pontuação, nessa ordem', (
      tester,
    ) async {
      await pumpLocalized(tester, child: const SizedBox());

      expect(
        lesson.spokenFeedback(
          result(isCorrect: false),
          score: const ModuleScoreEntity(score: 1, total: 3),
        ),
        'Não foi dessa vez.\n'
        'Resposta correta: Ignorar e denunciar.\n'
        'Promessas de dinheiro em dobro são golpe.\n'
        'Você está com 1 de 3 acertos.',
      );
    });

    testWidgets('sem explicação, sem pontuação e sem a correta', (
      tester,
    ) async {
      await pumpLocalized(tester, child: const SizedBox());

      expect(
        lesson.spokenFeedback(result(correctOptionId: 'zz', explanation: null)),
        'Você acertou!',
      );
    });
  });

  test('estado das alternativas antes e depois da correção', () {
    final [first, second, third, _] = lesson.options;

    expect(
      lesson.optionState(second, selectedOptionId: second.id),
      LessonOptionState.selected,
    );
    expect(
      lesson.optionState(first, selectedOptionId: second.id),
      LessonOptionState.idle,
    );
    final AnswerResultEntity wrong = result(isCorrect: false);
    expect(
      lesson.optionState(first, selectedOptionId: second.id, result: wrong),
      LessonOptionState.correct,
    );
    expect(
      lesson.optionState(second, selectedOptionId: second.id, result: wrong),
      LessonOptionState.wrong,
    );
    expect(
      lesson.optionState(third, selectedOptionId: second.id, result: wrong),
      LessonOptionState.idle,
    );
  });
}
