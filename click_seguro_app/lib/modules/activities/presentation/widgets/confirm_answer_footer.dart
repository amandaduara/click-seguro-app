import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/lesson_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Rodapé fixo das perguntas (RF-026): "Confirmar resposta" e, abaixo,
/// "Anterior"/"Próxima", desativados quando não podem (FR-005 da B2).
class ConfirmAnswerFooter extends StatelessWidget {
  const ConfirmAnswerFooter({
    super.key,
    required this.controller,
    required this.onConfirm,
  });

  final LessonController controller;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeButton(
              label: AppStrings.activitiesAnswerConfirm.tr(),
              loading: controller.isSubmitting,
              onPressed: controller.canConfirm ? onConfirm : null,
            ),
            const SizedBox(height: AppSpacing.s3),
            Row(
              children: [
                Expanded(
                  child: SafeButton(
                    label: AppStrings.activitiesLessonPrevious.tr(),
                    tone: SafeButtonTone.secondary,
                    onPressed: controller.canGoPrevious
                        ? controller.goPrevious
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: SafeButton(
                    label: AppStrings.activitiesLessonNext.tr(),
                    tone: SafeButtonTone.secondary,
                    onPressed: controller.canGoNext ? controller.goNext : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
