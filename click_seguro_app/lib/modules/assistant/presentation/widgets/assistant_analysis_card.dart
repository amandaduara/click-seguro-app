import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/safe_badge.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/modules/assistant/domain/entities/ai_analysis_entity.dart';
import 'package:click_seguro_app/modules/assistant/presentation/extensions/ai_analysis_presentation_extension.dart';
import 'package:click_seguro_app/modules/assistant/presentation/extensions/ai_threat_type_presentation_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Resultado da verificação (quadro "10 Assistente" do redesign 2.0): cartão
/// branco com o selo de risco ("Alto risco de golpe"…), a explicação e os
/// cuidados em lista. Com risco alto, a borda fica coral; no alto contraste
/// (sem sombra), sempre há borda.
class AssistantAnalysisCard extends StatelessWidget {
  const AssistantAnalysisCard({super.key, required this.analysis});

  final AiAnalysisEntity analysis;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    if (analysis.status != AiAnalysisStatus.success) {
      final String message = analysis.statusMessageKey;
      return SafeCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.triangleAlert, color: colors.warning),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                message.tr(),
                style: AppTypography.body.copyWith(
                  color: colors.textForeground,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final AssistantRiskLevel risk = analysis.riskLevel;
    final (SafeBadgeTone tone, IconData icon, String label) = switch (risk) {
      AssistantRiskLevel.high => (
        SafeBadgeTone.destructive,
        LucideIcons.triangleAlert,
        risk.labelKey,
      ),
      AssistantRiskLevel.medium => (
        SafeBadgeTone.warning,
        LucideIcons.circleAlert,
        risk.labelKey,
      ),
      AssistantRiskLevel.low => (
        SafeBadgeTone.success,
        LucideIcons.shieldCheck,
        risk.labelKey,
      ),
    };
    return Container(
      key: const ValueKey('assistant-analysis-result'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s5),
      // A caixa padrão dos cartões; risco alto troca a borda por coral.
      decoration: risk == AssistantRiskLevel.high
          ? SafeCard.decoration(
              colors,
            ).copyWith(border: Border.all(color: colors.primary, width: 2))
          : SafeCard.decoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Semantics(
              header: true,
              child: SafeBadge(
                key: const ValueKey('assistant-risk-badge'),
                tone: tone,
                icon: Icon(icon),
                child: Text(label.tr()),
              ),
            ),
          ),
          if (analysis.explanation?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              analysis.explanation!,
              style: AppTypography.bodyLarge.copyWith(
                color: colors.textForeground,
              ),
            ),
          ],
          if (analysis.tips.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s3),
            for (final tip in analysis.tips)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Icon(
                        risk == AssistantRiskLevel.low
                            ? LucideIcons.check
                            : LucideIcons.x,
                        size: 20,
                        color: risk == AssistantRiskLevel.low
                            ? colors.success
                            : colors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip,
                        style: AppTypography.body.copyWith(
                          color: colors.textBody,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          // Detalhes numa linha discreta no pé: tipo, risco e confiança
          // (a spec 016 pede risco e confiança, mesmo quando indisponíveis).
          const SizedBox(height: AppSpacing.s3),
          Wrap(
            spacing: AppSpacing.s4,
            runSpacing: AppSpacing.s1,
            children: [
              _Detail(value: analysis.threatType.labelKey.tr()),
              _Detail(
                label: AppStrings.assistantRisk.tr(),
                value: _percentage(analysis.riskScore),
              ),
              _Detail(
                label: AppStrings.assistantConfidence.tr(),
                value: _percentage(analysis.confidence),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _percentage(double? value) => value == null
      ? AppStrings.assistantUnavailable.tr()
      : '${value.round()}%';
}

/// Um item da linha de detalhes: rótulo apagado e valor em destaque.
class _Detail extends StatelessWidget {
  const _Detail({this.label, required this.value});

  final String? label;
  final String value;

  @override
  // Wrap, e não Row: com letra grande, o valor desce para a linha de baixo.
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.s1,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (label case final String label)
        Text(
          label,
          style: AppTypography.body.copyWith(
            color: context.colors.textMutedForeground,
          ),
        ),
      Text(
        value,
        style: AppTypography.label.copyWith(
          color: context.colors.textForeground,
        ),
      ),
    ],
  );
}
