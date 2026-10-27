import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/answer_result_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/lesson_option_card.dart';
import 'package:easy_localization/easy_localization.dart';

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

  /// O que "Ouvir" lê no painel: resultado, correta, explicação e pontuação,
  /// nessa ordem (clarificação Q4 de specs/018).
  String spokenFeedback(AnswerResultEntity result, {ModuleScoreEntity? score}) {
    final LessonOptionEntity? correct = correctOption(result);
    final String? explanation = result.explanation;
    return [
      (result.isCorrect
              ? AppStrings.activitiesFeedbackCorrect
              : AppStrings.activitiesFeedbackWrong)
          .tr(),
      if (correct != null)
        AppStrings.activitiesFeedbackCorrectOption.tr(args: [correct.text]),
      ?explanation,
      if (score != null)
        AppStrings.activitiesFeedbackScore.tr(
          args: ['${score.score}', '${score.total}'],
        ),
    ].map(_sentence).join('\n');
  }
}

/// Cada parte termina com pontuação, para a voz fazer a pausa.
String _sentence(String text) =>
    RegExp(r'[.!?]$').hasMatch(text) ? text : '$text.';
