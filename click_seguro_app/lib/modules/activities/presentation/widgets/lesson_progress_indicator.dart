import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// "Pergunta X de Y" e uma marca por pergunta: respondida com check, atual
/// destacada (FR-006). Lido como um item só pelo leitor de tela.
class LessonProgressIndicator extends StatelessWidget {
  const LessonProgressIndicator({
    super.key,
    required this.lessons,
    required this.currentIndex,
  });

  final List<LessonEntity> lessons;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final String position = '${currentIndex + 1}';
    final String total = '${lessons.length}';
    final int completed = lessons.where((l) => l.isCompleted).length;
    return Semantics(
      label: AppStrings.activitiesLessonProgressSemantics.tr(
        args: [position, total, '$completed'],
      ),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Um segmento por pergunta: respondidas em coral, a atual em coral
          // claro, as outras em creme (redesign 2.0).
          Row(
            children: [
              for (final (index, lesson) in lessons.indexed) ...[
                if (index > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: lesson.isCompleted
                          ? colors.primary
                          : index == currentIndex
                          ? colors.primary.withValues(alpha: 0.35)
                          : colors.surfaceStrong,
                      borderRadius: AppSpacing.radiusFull,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            AppStrings.activitiesLessonPosition.tr(args: [position, total]),
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
