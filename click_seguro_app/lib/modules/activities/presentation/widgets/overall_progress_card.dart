import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/activities_dashboard_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// "Seu progresso": lições concluídas de todas as disponíveis (FR-002).
class OverallProgressCard extends StatelessWidget {
  const OverallProgressCard({super.key, required this.dashboard});

  final ActivitiesDashboardEntity dashboard;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppSpacing.radius2xl,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                AppStrings.activitiesOverallTitle.tr(),
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.secondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s1),
            Text(
              AppStrings.activitiesOverallCount.tr(
                args: [
                  '${dashboard.totalCompleted}',
                  '${dashboard.totalAvailable}',
                ],
              ),
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                color: colors.textForeground,
              ),
            ),
            const SizedBox(height: AppSpacing.s3),
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: AppSpacing.radiusFull,
                child: LinearProgressIndicator(
                  value: dashboard.overallProgress,
                  minHeight: 8,
                  color: colors.primary,
                  backgroundColor: colors.input,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
