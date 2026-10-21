import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_badge.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AssistantAnalysisCard extends StatelessWidget {
  const AssistantAnalysisCard({super.key, required this.analysis});

  final AiAnalysisEntity analysis;

  String get _typeKey => switch (analysis.threatType) {
    AiThreatType.phishing => AppStrings.assistantThreatPhishing,
    AiThreatType.fakeNews => AppStrings.assistantThreatFakeNews,
    AiThreatType.financialScam => AppStrings.assistantThreatFinancialScam,
    AiThreatType.socialEngineering =>
      AppStrings.assistantThreatSocialEngineering,
    AiThreatType.spam => AppStrings.assistantThreatSpam,
    AiThreatType.safe => AppStrings.assistantThreatSafe,
    AiThreatType.uncertain => AppStrings.assistantThreatUncertain,
    AiThreatType.unknown => AppStrings.assistantUnknown,
    null => AppStrings.assistantUnavailable,
  };

  @override
  Widget build(BuildContext context) {
    final bool successful = analysis.status == AiAnalysisStatus.success;
    final AppPalette colors = context.colors;
    if (!successful) {
      final String message = switch (analysis.status) {
        AiAnalysisStatus.error => AppStrings.assistantStatusError,
        AiAnalysisStatus.rateLimited => AppStrings.assistantStatusRateLimited,
        _ => AppStrings.assistantUnknown,
      };
      return SafeCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.triangleAlert, color: colors.warning),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                message.tr(),
                style: TextStyle(color: colors.textForeground),
              ),
            ),
          ],
        ),
      );
    }

    final SafeBadgeTone tone = switch (analysis.threatType) {
      AiThreatType.safe => SafeBadgeTone.success,
      AiThreatType.unknown ||
      AiThreatType.uncertain ||
      null => SafeBadgeTone.warning,
      _ => SafeBadgeTone.destructive,
    };
    return SafeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.assistantAnalysisResult.tr(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          _ThreatBadge(
            label: _typeKey.tr(),
            color: switch (tone) {
              SafeBadgeTone.success => colors.success,
              SafeBadgeTone.warning => colors.warning,
              SafeBadgeTone.destructive => colors.destructive,
              _ => colors.textMutedForeground,
            },
            icon: tone == SafeBadgeTone.success
                ? LucideIcons.shieldCheck
                : LucideIcons.circleAlert,
          ),
          const SizedBox(height: AppSpacing.s3),
          _Metric(
            label: AppStrings.assistantRisk.tr(),
            value: _percentage(analysis.riskScore),
          ),
          const SizedBox(height: AppSpacing.s2),
          _Metric(
            label: AppStrings.assistantConfidence.tr(),
            value: _percentage(analysis.confidence),
          ),
          if (analysis.explanation?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              AppStrings.assistantExplanation.tr(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s1),
            Text(
              analysis.explanation!,
              style: TextStyle(color: colors.textForeground),
            ),
          ],
          if (analysis.tips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              AppStrings.assistantTips.tr(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s1),
            for (final tip in analysis.tips)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.check, size: 18, color: colors.primary),
                    const SizedBox(width: AppSpacing.s2),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(color: colors.textForeground),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _percentage(double? value) => value == null
      ? AppStrings.assistantUnavailable.tr()
      : '${value.round()}%';
}

class _ThreatBadge extends StatelessWidget {
  const _ThreatBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.s3,
      vertical: AppSpacing.s2,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: AppSpacing.radiusFull,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: AppSpacing.s2),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(color: context.colors.textMutedForeground),
        ),
      ),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          softWrap: true,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.secondary,
          ),
        ),
      ),
    ],
  );
}
