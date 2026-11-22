import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/answer_result_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/lesson_option_card.dart';
import 'package:click_seguro_app/modules/common/presentation/controller/read_aloud_controller.dart';
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
  /// nessa ordem (clarificação Q4 de specs/018). O texto da alternativa e a
  /// explicação vêm do banco (voz em português); o resto é texto do app, no
  /// idioma do app (specs/025).
  List<SpeechPart> feedbackParts(
    AnswerResultEntity result, {
    ModuleScoreEntity? score,
  }) {
    final LessonOptionEntity? correct = correctOption(result);
    final String? explanation = result.explanation;
    return [
      SpeechPart(
        _sentence(
          (result.isCorrect
                  ? AppStrings.activitiesFeedbackCorrect
                  : AppStrings.activitiesFeedbackWrong)
              .tr(),
        ),
      ),
      if (correct != null) ...[
        SpeechPart(
          _sentence(AppStrings.activitiesFeedbackCorrectOptionLabel.tr()),
        ),
        SpeechPart(_sentence(correct.text), content: true),
      ],
      if (explanation != null && explanation.trim().isNotEmpty)
        SpeechPart(_sentence(explanation), content: true),
      if (score != null)
        SpeechPart(
          _sentence(
            AppStrings.activitiesFeedbackScore.tr(
              args: ['${score.score}', '${score.total}'],
            ),
          ),
        ),
    ];
  }
}

/// Cada parte termina com pontuação, para a voz fazer a pausa.
String _sentence(String text) {
  final String trimmed = text.trim();
  return RegExp(r'[.!?]$').hasMatch(trimmed) ? trimmed : '$trimmed.';
}
