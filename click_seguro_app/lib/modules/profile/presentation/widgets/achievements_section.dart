import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/achievement_entity.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/area_state.dart';
import 'package:click_seguro_app/modules/profile/presentation/widgets/area_notice.dart';
import 'package:click_seguro_app/modules/profile/presentation/widgets/medal_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// "Conquistas (N)" com a faixa de medalhas que desliza e "Ver todas".
class AchievementsSection extends StatelessWidget {
  const AchievementsSection({
    super.key,
    required this.state,
    required this.achievedCount,
    required this.onSeeAll,
    required this.onRetry,
  });

  final AreaState<List<AchievementEntity>> state;
  final int achievedCount;
  final ValueChanged<List<AchievementEntity>> onSeeAll;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final AreaState<List<AchievementEntity>> current = state;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppSpacing.radius3xl,
        border: Border.all(color: colors.border),
        boxShadow: colors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Com a fonte grande, "Ver todas" desce para a linha de baixo.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                header: true,
                child: Text(
                  current is AreaLoaded
                      ? AppStrings.profileAchievementsCount.tr(
                          args: ['$achievedCount'],
                        )
                      : AppStrings.profileAchievements.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.secondary,
                  ),
                ),
              ),
              if (current is AreaLoaded<List<AchievementEntity>>)
                TextButton(
                  onPressed: () => onSeeAll(current.value),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    foregroundColor: colors.primary,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(AppStrings.profileAchievementsSeeAll.tr()),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 18),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          switch (current) {
            AreaLoading() => Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Center(
                child: CircularProgressIndicator(color: colors.primary),
              ),
            ),
            AreaFailed() => AreaNotice(
              message: AppStrings.profileAchievementsFailed.tr(),
              onRetry: onRetry,
            ),
            AreaLoaded(:final value) => _MedalStrip(achievements: value),
          },
        ],
      ),
    );
  }
}

/// Faixa horizontal: sem altura fixa, para caber a fonte grande.
class _MedalStrip extends StatelessWidget {
  const _MedalStrip({required this.achievements});

  final List<AchievementEntity> achievements;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, achievement) in achievements.indexed) ...[
              if (index > 0) const SizedBox(width: AppSpacing.s3),
              MedalCard(achievement: achievement, width: MedalCard.stripWidth),
            ],
          ],
        ),
      ),
    );
  }
}
