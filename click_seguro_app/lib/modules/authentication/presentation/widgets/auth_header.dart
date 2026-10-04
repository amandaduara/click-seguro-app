import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Marca + "Bem-vindo ao SafeNews" (wireframe, LoginScreen).
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.textPrimaryForeground,
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.authWelcome.tr(),
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMutedForeground,
                  ),
                ),
                Text(
                  AppStrings.authBrand.tr(),
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.secondary,
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
