import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/app_logo.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Marca + "Bem-vindo ao Click Seguro" (wireframe, LoginScreen).
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Row(
        children: [
          const AppLogo(),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.authWelcome.tr(),
                  style: textTheme.bodyMedium?.copyWith(
                    color: context.colors.textMutedForeground,
                  ),
                ),
                Text(
                  AppStrings.authBrand.tr(),
                  style: textTheme.headlineSmall?.copyWith(
                    color: context.colors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
