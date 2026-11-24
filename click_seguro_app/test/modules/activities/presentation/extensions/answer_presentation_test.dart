import 'package:click_seguro_app/modules/activities/data/models/answer_result_model.dart';
import 'package:click_seguro_app/modules/activities/data/models/module_detail_model.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/answer_result_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/extensions/answer_presentation.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/lesson_option_card.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
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

  List<(String, bool)> parts(List<SpeechPart> parts) => [
    for (final part in parts) (part.text, part.content),
  ];

  group('trechos falados do feedback (US5, specs/025)', () {
    testWidgets('resultado, correta, explicação e pontuação, nessa ordem; '
        'o que vem do banco é conteúdo', (tester) async {
      await pumpLocalized(tester, child: const SizedBox());

      expect(
        parts(
          lesson.feedbackParts(
            result(isCorrect: false),
            score: const ModuleScoreEntity(score: 1, total: 3),
          ),
        ),
        [
          ('Não foi dessa vez.', false),
          ('Resposta correta.', false),
          ('Ignorar e denunciar.', true),
          ('Promessas de dinheiro em dobro são golpe.', true),
          ('Você está com 1 de 3 acertos.', false),
        ],
      );
    });

    testWidgets('com o app em inglês, só os textos do app mudam', (
      tester,
    ) async {
      await pumpLocalized(
        tester,
        child: const SizedBox(),
        locale: const Locale('en', 'US'),
      );

      expect(parts(lesson.feedbackParts(result())), [
        ('You got it right!', false),
        ('Correct answer.', false),
        ('Ignorar e denunciar.', true),
        ('Promessas de dinheiro em dobro são golpe.', true),
      ]);
    });

    testWidgets('sem explicação, sem pontuação e sem a correta', (
      tester,
    ) async {
      await pumpLocalized(tester, child: const SizedBox());

      expect(
        parts(
          lesson.feedbackParts(
            result(correctOptionId: 'zz', explanation: null),
          ),
        ),
        [('Você acertou!', false)],
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
