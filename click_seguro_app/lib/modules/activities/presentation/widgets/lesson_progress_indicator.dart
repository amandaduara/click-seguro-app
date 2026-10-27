import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/lesson_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// "Pergunta X de Y" e uma marca por pergunta: respondida com check, atual
/// destacada (FR-006). Lido como um item só pelo leitor de tela.
class LessonProgressIndicator extends StatelessWidget {
  const LessonProgressIndicator({
    super.key,
    required this.lessons,
    required this.currentIndex,
  });

  static const double markSize = 28;

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
          Text(
            AppStrings.activitiesLessonPosition.tr(args: [position, total]),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textMutedForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              for (final (index, lesson) in lessons.indexed)
                _Mark(done: lesson.isCompleted, current: index == currentIndex),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.done, required this.current});

  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return Container(
      width: LessonProgressIndicator.markSize,
      height: LessonProgressIndicator.markSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? colors.success : colors.input,
        border: current ? Border.all(color: colors.primary, width: 3) : null,
      ),
      child: done
          ? Icon(LucideIcons.check, size: 16, color: colors.card)
          : null,
    );
  }
}
