import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Convite do visitante (quadro "Perfil — visitante"): nenhum pedido ao
/// serviço (RN-003).
class GuestInvite extends StatelessWidget {
  const GuestInvite({super.key});

  static const List<String> _benefits = [
    AppStrings.profileGuestBenefitProgress,
    AppStrings.profileGuestBenefitSaved,
    AppStrings.profileGuestBenefitAlerts,
    AppStrings.profileGuestBenefitAchievements,
  ];

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s6),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: AppSpacing.radius3xl,
            border: Border.all(color: colors.border),
            boxShadow: colors.shadowSm,
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(alpha: 0.12),
                ),
                child: Icon(
                  LucideIcons.userRound,
                  size: 34,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Semantics(
                header: true,
                child: Text(
                  AppStrings.profileGuestTitle.tr(),
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: colors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                AppStrings.profileGuestBody.tr(),
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  color: colors.textMutedForeground,
                ),
              ),
              const SizedBox(height: AppSpacing.s6),
              SafeButton(
                label: AppStrings.profileGuestAction.tr(),
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s5),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: AppSpacing.radius3xl,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  AppStrings.profileGuestBenefitsTitle.tr(),
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.secondary,
                  ),
                ),
              ),
              for (final benefit in _benefits)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.circleCheck,
                        size: 22,
                        color: colors.success,
                      ),
                      const SizedBox(width: AppSpacing.s3),
                      Expanded(
                        child: Text(
                          benefit.tr(),
                          style: textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            color: colors.textForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
