import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Como uma alternativa aparece: sem marcação, escolhida, ou, depois da
/// correção, a correta e a escolhida errada (R8 de specs/018).
enum LessonOptionState { idle, selected, correct, wrong }

/// Uma alternativa numerada, escolhível (opção única). Correta e errada têm
/// ícone e texto, não só cor (FR-001, FR-005).
class LessonOptionCard extends StatelessWidget {
  const LessonOptionCard({
    super.key,
    required this.number,
    required this.text,
    this.state = LessonOptionState.idle,
    this.onTap,
  });

  final int number;
  final String text;
  final LessonOptionState state;

  /// `null` quando não pode escolher (enviando ou já corrigida).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final (Color? accent, IconData? icon, String? status) = switch (state) {
      LessonOptionState.idle => (null, null, null),
      LessonOptionState.selected => (
        colors.primary,
        LucideIcons.circleDot,
        null,
      ),
      LessonOptionState.correct => (
        colors.success,
        LucideIcons.circleCheck,
        AppStrings.activitiesOptionCorrect.tr(),
      ),
      LessonOptionState.wrong => (
        colors.destructive,
        LucideIcons.circleX,
        AppStrings.activitiesOptionWrong.tr(),
      ),
    };
    return MergeSemantics(
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: state == LessonOptionState.selected,
        enabled: onTap != null,
        child: Material(
          color: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.radius2xl,
            side: BorderSide(
              color: accent ?? colors.border,
              width: accent == null ? 1 : 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$number',
                        textScaler: TextScaler.noScaling,
                        style: textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                              color: colors.textForeground,
                            ),
                          ),
                          if (status != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.s1,
                              ),
                              child: Text(
                                status,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: AppSpacing.s3),
                      ExcludeSemantics(
                        child: Icon(icon, size: 24, color: accent),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
