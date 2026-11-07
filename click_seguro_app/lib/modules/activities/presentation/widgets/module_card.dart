import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_badge.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_summary_entity.dart';
import 'package:click_seguro_app/modules/activities/presentation/extensions/module_status_presentation.dart';
import 'package:click_seguro_app/modules/activities/presentation/widgets/module_icon.dart';
import 'package:easy_localization/easy_localization.dart';
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
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String progress = module.isAvailable
        ? AppStrings.activitiesModuleCount.tr(
            args: ['${module.completedCount}', '${module.lessonsCount}'],
          )
        : AppStrings.activitiesModuleUnavailable.tr();
    final String status = module.status.label;
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
      child: Material(
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.radius2xl,
          side: BorderSide(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModuleIcon(url: module.iconUrl),
                const SizedBox(height: AppSpacing.s3),
                Text(
                  module.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.secondary,
                  ),
                ),
                if (module.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    module.description,
                    maxLines: compact ? compactDescriptionLines : null,
                    overflow: compact ? TextOverflow.ellipsis : null,
                    style: textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      color: colors.textForeground,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s3),
                Text(
                  progress,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: colors.textMutedForeground,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                SafeBadge(
                  tone: module.status.badgeTone,
                  icon: Icon(module.status.icon, size: 14),
                  child: Text(status),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
