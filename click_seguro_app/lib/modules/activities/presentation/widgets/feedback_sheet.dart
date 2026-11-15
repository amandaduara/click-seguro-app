import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/answer_result_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_score_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/extensions/answer_presentation.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/spring_in.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/illustrations/app_illustration.dart';
import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
import 'package:click_seguro_app/core/widgets/safe_sheet.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// O que a pessoa escolheu no painel; `null` quando fechou pelo voltar.
/// `result` só na última pergunta com o módulo concluído (specs/020 R1).
enum FeedbackAction { next, finish, result }

/// Painel de feedback (RF-026). Não fecha com toque fora nem arrastando, para
/// não sumir antes de a pessoa ler a explicação (clarificação Q3 de
/// specs/018); o voltar do aparelho fecha.
Future<FeedbackAction?> showFeedbackSheet(
  BuildContext context, {
  required LessonEntity lesson,
  required AnswerResultEntity result,
  required bool isLast,
  bool completed = false,
  ModuleScoreEntity? score,
  Widget? listen,
}) => showModalBottomSheet<FeedbackAction>(
  context: context,
  isDismissible: false,
  enableDrag: false,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: context.colors.card,
  // Sobe em 400 ms (FR-020); sem animação com reduzir animações.
  sheetAnimationStyle: AnimationStyle(
    duration: AppMotion.of(context).long,
    curve: AppMotion.enter,
  ),
  builder: (_) => FeedbackSheet(
    lesson: lesson,
    result: result,
    isLast: isLast,
    completed: completed,
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
    this.completed = false,
    this.score,
    this.listen,
  });

  final LessonEntity lesson;
  final AnswerResultEntity result;
  final bool isLast;

  /// Todas as perguntas respondidas: na última, "Ver resultado".
  final bool completed;
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
    final AnswerResultEntity result = widget.result;
    final Color accent = result.isCorrect ? colors.success : colors.destructive;
    final LessonOptionEntity? correct = widget.lesson.correctOption(result);
    final String? explanation = result.explanation;
    final ModuleScoreEntity? score = widget.score;
    final (FeedbackAction action, String label) = switch (widget) {
      FeedbackSheet(isLast: false) => (
        FeedbackAction.next,
        AppStrings.activitiesFeedbackNext,
      ),
      FeedbackSheet(completed: true) => (
        FeedbackAction.result,
        AppStrings.activitiesFeedbackResult,
      ),
      _ => (FeedbackAction.finish, AppStrings.activitiesFeedbackFinish),
    };
    // Redesign 2.0 (Figma, quadro 08): ilustração do acerto (com mola) ou a
    // lâmpada do erro, o título forte e o "Por quê?" num bloco creme.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: SingleChildScrollView(
        child: SafeSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SpringIn(
                    child: SafeIllustration(
                      result.isCorrect
                          ? AppIllustration.answerCorrect
                          : AppIllustration.answerWrong,
                      height: 84,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          liveRegion: true,
                          header: true,
                          child: Text(
                            (result.isCorrect
                                    ? AppStrings.activitiesFeedbackCorrect
                                    : AppStrings.activitiesFeedbackWrong)
                                .tr(),
                            style: AppTypography.title1.copyWith(color: accent),
                          ),
                        ),
                        if (score != null) ...[
                          const SizedBox(height: AppSpacing.s1),
                          Text(
                            AppStrings.activitiesFeedbackScore.tr(
                              args: ['${score.score}', '${score.total}'],
                            ),
                            style: AppTypography.caption.copyWith(
                              color: colors.textMutedForeground,
                            ),
                          ),
                        ],
                      ],
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
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textForeground,
                  ),
                ),
              ],
              if (explanation != null) ...[
                const SizedBox(height: AppSpacing.s4),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: AppSpacing.radiusMd,
                    border: colors.shadow.isEmpty
                        ? Border.all(color: colors.border)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          AppStrings.activitiesFeedbackExplanation.tr(),
                          style: AppTypography.label.copyWith(
                            fontSize: 16,
                            color: colors.textForeground,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s1),
                      Text(
                        explanation,
                        style: AppTypography.body.copyWith(
                          fontSize: 16,
                          height: 1.5,
                          color: colors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (widget.listen case final Widget listen) ...[
                const SizedBox(height: AppSpacing.s4),
                listen,
              ],
              const SizedBox(height: AppSpacing.s5),
              SafeButton(
                label: label.tr(),
                iconRight: action == FeedbackAction.next
                    ? const Icon(LucideIcons.arrowRight)
                    : null,
                onPressed: _closing ? null : () => _close(action),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
