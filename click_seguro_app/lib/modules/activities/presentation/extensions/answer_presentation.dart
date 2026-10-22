import 'package:click_seguro_app/modules/activities/domain/entities/answer_result_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/lesson_option_card.dart';

extension AnswerPresentation on LessonEntity {
  /// A alternativa correta, se estiver entre as mostradas (dado inconsistente
  /// do serviço → `null`, sem destaque).
  LessonOptionEntity? correctOption(AnswerResultEntity result) {
    for (final LessonOptionEntity option in options) {
      if (option.id == result.correctOptionId) return option;
    }
    return null;
  }

  /// Antes da correção, só a escolhida aparece marcada; depois, a correta e a
  /// escolhida errada (R8 de specs/018).
  LessonOptionState optionState(
    LessonOptionEntity option, {
    String? selectedOptionId,
    AnswerResultEntity? result,
  }) {
    if (result == null) {
      return option.id == selectedOptionId
          ? LessonOptionState.selected
          : LessonOptionState.idle;
    }
    if (option.id == result.correctOptionId) return LessonOptionState.correct;
    if (option.id == selectedOptionId) return LessonOptionState.wrong;
    return LessonOptionState.idle;
  }
}
