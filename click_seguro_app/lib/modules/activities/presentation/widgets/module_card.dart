import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_badge.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_summary_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/extensions/module_status_presentation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/illustrations/illustration_theme.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
import 'package:click_seguro_app/core/widgets/safe_progress.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_status.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:flutter/material.dart';

/// Cartão de um módulo no painel (FR-003, FR-004). [compact] (duas colunas,
/// letra normal) limita a descrição a 3 linhas; o leitor de tela lê sempre a
/// descrição inteira (FR-003a).
class ModuleCard extends StatelessWidget {
  const ModuleCard({
    super.key,
    required this.module,
    required this.compact,
    this.onTap,
  });

  static const int compactDescriptionLines = 3;

  final ModuleSummaryEntity module;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final IllustrationTheme theme = IllustrationTheme.fromText(module.title);
    final String progress = module.isAvailable
        ? AppStrings.activitiesModuleCount.tr(
            args: ['${module.completedCount}', '${module.lessonsCount}'],
          )
        : AppStrings.activitiesModuleUnavailable.tr();
    final String status = module.status.label;
    final double value = module.lessonsCount == 0
        ? 0
        : module.completedCount / module.lessonsCount;
    return Semantics(
      container: true,
      button: onTap != null,
      label: [
        module.title,
        status,
        progress,
        module.description,
      ].where((part) => part.isNotEmpty).join('. '),
      excludeSemantics: true,
      // Redesign 2.0 (estilo Airbnb): ilustração do tema no topo, selo de
      // status sobre ela, título, descrição, lições e barra de progresso.
      child: SafeCard(
        padded: false,
        interactive: onTap != null,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, AppSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Módulo indisponível (CB-012): capa apagada.
              Opacity(
                opacity: module.isAvailable ? 1 : 0.5,
                // No esqueleto (carregando), a capa é só um bloco cinza, sem a
                // ilustração (validação da usuária, specs/023).
                child: SafeSkeleton.leaf(
                  ClipRRect(
                    borderRadius: AppSpacing.radiusMd,
                    child: Container(
                      height: 150,
                      color: theme.pastel(colors),
                      padding: const EdgeInsets.all(AppSpacing.s3),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          SafeIllustration(theme.illustration),
                          Align(
                            alignment: Alignment.topLeft,
                            child: SafeBadge(
                              tone: SafeBadgeTone.onImage,
                              icon: Icon(
                                module.status.icon,
                                color: module.status.iconColor(colors),
                              ),
                              child: Text(status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            module.title,
                            style: AppTypography.title3.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.textForeground,
                            ),
                          ),
                          if (module.description.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.s1),
                            Text(
                              module.description,
                              maxLines: compact
                                  ? compactDescriptionLines
                                  : null,
                              overflow: compact ? TextOverflow.ellipsis : null,
                              style: AppTypography.body.copyWith(
                                fontSize: 16,
                                height: 1.4,
                                color: colors.textBody,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.s1),
                          Text(
                            progress,
                            style: AppTypography.caption.copyWith(
                              color: colors.textMutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (module.isAvailable) ...[
                      const SizedBox(width: AppSpacing.s3),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.chevronRight,
                          color: colors.textForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (module.isAvailable) ...[
                const SizedBox(height: AppSpacing.s3),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s2,
                  ),
                  child: SafeProgressBar(
                    value: value,
                    tone: module.status == ModuleStatus.completed
                        ? SafeProgressTone.success
                        : SafeProgressTone.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
