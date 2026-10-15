import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// `/settings` sem conta (link direto ou sessão expirada): só o convite, sem
/// pedido ao serviço (RN-003, R6 de specs/013).
class SettingsGuestInvite extends StatelessWidget {
  const SettingsGuestInvite({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(LucideIcons.userRound, size: 40, color: colors.primary),
            const SizedBox(height: AppSpacing.s3),
            Semantics(
              header: true,
              child: Text(
                AppStrings.settingsGuestTitle.tr(),
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colors.secondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              AppStrings.settingsGuestBody.tr(),
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.s6),
            SafeButton(
              label: AppStrings.settingsGuestAction.tr(),
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}
