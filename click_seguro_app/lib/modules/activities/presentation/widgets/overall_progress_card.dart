import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/activities_dashboard_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/core/widgets/safe_progress.dart';
import 'package:flutter/material.dart';

/// "Seu progresso": lições concluídas de todas as disponíveis (FR-002).
class OverallProgressCard extends StatelessWidget {
  const OverallProgressCard({super.key, required this.dashboard});

  final ActivitiesDashboardEntity dashboard;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final int percent = (dashboard.overallProgress * 100).round();
    // Redesign 2.0: anel de progresso e o texto ao lado, em cartão creme.
    return SafeCard(
      elevation: SafeCardElevation.flat,
      child: Row(
        children: [
          ExcludeSemantics(
            child: SafeProgressRing(
              value: dashboard.overallProgress,
              label: '$percent%',
            ),
          ),
          const SizedBox(width: AppSpacing.s5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    AppStrings.activitiesOverallTitle.tr(),
                    style: AppTypography.title3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textForeground,
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
                  style: AppTypography.body.copyWith(
                    fontSize: 17,
                    height: 1.4,
                    color: colors.textBody,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
