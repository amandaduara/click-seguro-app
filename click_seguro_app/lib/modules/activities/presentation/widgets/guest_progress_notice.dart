import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Aviso do visitante: sem conta, o progresso vale até fechar o app, e criar
/// a conta leva o progresso junto (FR-010, clarificação de 2026-10-19).
class GuestProgressNotice extends StatelessWidget {
  const GuestProgressNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: AppSpacing.radius2xl,
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    LucideIcons.info,
                    size: 22,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Text(
                    AppStrings.activitiesGuestNotice.tr(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      color: colors.textForeground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            SafeButton(
              label: AppStrings.activitiesGuestAction.tr(),
              size: SafeButtonSize.compact,
              tone: SafeButtonTone.secondary,
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}
