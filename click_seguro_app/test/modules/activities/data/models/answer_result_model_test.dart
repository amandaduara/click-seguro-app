import 'package:click_seguro_app/modules/activities/data/models/answer_result_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/activities_fixtures.dart';

void main() {
  test('JSON do serviço → resultado da resposta', () {
    final result = AnswerResultModel.fromJson(
      answerJson(isCorrect: false),
    ).toEntity();

    expect(result.isCorrect, isFalse);
    expect(result.correctOptionId, 'l1-o1');
    expect(result.explanation, 'Promessas de dinheiro em dobro são golpe.');
  });

  test('explicação ausente ou vazia → null', () {
    expect(
      AnswerResultModel.fromJson(
        answerJson(explanation: null),
      ).toEntity().explanation,
      isNull,
    );
    expect(
      AnswerResultModel.fromJson(
        answerJson(explanation: ''),
      ).toEntity().explanation,
      isNull,
    );
  });
}
