import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Convite para entrar ou criar conta (RN-003, CB-011). Fecha com `true`
/// quando a pessoa aceita ir ao login.
class AccountRequiredSheet extends StatelessWidget {
  const AccountRequiredSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                AppStrings.commonAccountRequiredTitle.tr(),
                style: textTheme.titleMedium?.copyWith(
                  color: context.colors.secondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              AppStrings.commonAccountRequiredBody.tr(),
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.s6),
            SafeButton(
              label: AppStrings.commonAccountRequiredAction.tr(),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.s3),
            SafeButton(
              label: AppStrings.commonAccountRequiredDismiss.tr(),
              tone: SafeButtonTone.ghost,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
