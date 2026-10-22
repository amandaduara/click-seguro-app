import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/answer_result_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/extensions/answer_presentation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// O que a pessoa escolheu no painel; `null` quando fechou pelo voltar.
enum FeedbackAction { next, finish }

/// Painel de feedback (RF-026). Não fecha com toque fora nem arrastando, para
/// não sumir antes de a pessoa ler a explicação (clarificação Q3 de
/// specs/018); o voltar do aparelho fecha.
Future<FeedbackAction?> showFeedbackSheet(
  BuildContext context, {
  required LessonEntity lesson,
  required AnswerResultEntity result,
  required bool isLast,
  ModuleScoreEntity? score,
  Widget? listen,
}) => showModalBottomSheet<FeedbackAction>(
  context: context,
  isDismissible: false,
  enableDrag: false,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: context.colors.card,
  builder: (_) => FeedbackSheet(
    lesson: lesson,
    result: result,
    isLast: isLast,
    score: score,
    listen: listen,
  ),
);

class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({
    super.key,
    required this.lesson,
    required this.result,
    required this.isLast,
    this.score,
    this.listen,
  });

  final LessonEntity lesson;
  final AnswerResultEntity result;
  final bool isLast;
  final ModuleScoreEntity? score;

  /// "Ouvir"/"Parar" do feedback (some sem voz no idioma do app).
  final Widget? listen;

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  /// O primeiro toque fecha; um segundo, antes de o painel sumir, fecharia
  /// também a tela de perguntas (achado U1 da análise).
  bool _closing = false;

  void _close(FeedbackAction action) {
    if (_closing) return;
    setState(() => _closing = true);
    Navigator.of(context).pop(action);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AnswerResultEntity result = widget.result;
    final Color accent = result.isCorrect ? colors.success : colors.destructive;
    final LessonOptionEntity? correct = widget.lesson.correctOption(result);
    final String? explanation = result.explanation;
    final ModuleScoreEntity? score = widget.score;
    final FeedbackAction action = widget.isLast
        ? FeedbackAction.finish
        : FeedbackAction.next;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s6,
          AppSpacing.s5,
          AppSpacing.s5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    result.isCorrect
                        ? LucideIcons.circleCheck
                        : LucideIcons.circleX,
                    size: 32,
                    color: accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    header: true,
                    child: Text(
                      (result.isCorrect
                              ? AppStrings.activitiesFeedbackCorrect
                              : AppStrings.activitiesFeedbackWrong)
                          .tr(),
                      style: textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (correct != null) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                AppStrings.activitiesFeedbackCorrectOption.tr(
                  args: [correct.text],
                ),
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.textForeground,
                ),
              ),
            ],
            if (explanation != null) ...[
              const SizedBox(height: AppSpacing.s4),
              Semantics(
                header: true,
                child: Text(
                  AppStrings.activitiesFeedbackExplanation.tr(),
                  style: textTheme.titleSmall?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                explanation,
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  color: colors.textForeground,
                ),
              ),
            ],
            if (score != null) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                AppStrings.activitiesFeedbackScore.tr(
                  args: ['${score.score}', '${score.total}'],
                ),
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  color: colors.textMutedForeground,
                ),
              ),
            ],
            if (widget.listen case final Widget listen) ...[
              const SizedBox(height: AppSpacing.s4),
              listen,
            ],
            const SizedBox(height: AppSpacing.s5),
            SafeButton(
              label:
                  (widget.isLast
                          ? AppStrings.activitiesFeedbackFinish
                          : AppStrings.activitiesFeedbackNext)
                      .tr(),
              onPressed: _closing ? null : () => _close(action),
            ),
          ],
        ),
      ),
    );
  }
}
