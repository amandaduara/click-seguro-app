import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Alterar senha sem conta (link direto ou sessão expirada): só o convite,
/// num cartão padrão, sem pedido ao serviço (RN-003). As Configurações do
/// visitante não o usam mais (R6 de specs/014).
class SettingsGuestInvite extends StatelessWidget {
  const SettingsGuestInvite({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s6),
      child: SafeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  shape: BoxShape.circle,
                  border: colors.shadow.isEmpty
                      ? Border.all(color: colors.border)
                      : null,
                ),
                child: Icon(
                  LucideIcons.userRound,
                  size: 34,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Semantics(
              header: true,
              child: Text(
                AppStrings.settingsGuestTitle.tr(),
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontSize: AppTypography.title2.fontSize,
                  fontWeight: FontWeight.w800,
                  color: colors.secondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              AppStrings.settingsGuestBody.tr(),
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                fontSize: AppTypography.body.fontSize,
                height: 1.5,
                color: colors.textBody,
              ),
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
