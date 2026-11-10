import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/app_logo.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Marca + "Bem-vindo ao Click Seguro" (wireframe, LoginScreen).
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.colors.primarySoft,
              borderRadius: AppSpacing.radiusLg,
            ),
            alignment: Alignment.center,
            child: const AppLogo(size: 42),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.authWelcome.tr(),
                  style: AppTypography.caption.copyWith(
                    fontSize: 16,
                    color: context.colors.textMutedForeground,
                  ),
                ),
                Text(
                  AppStrings.authBrand.tr(),
                  style: AppTypography.title1.copyWith(
                    color: context.colors.textForeground,
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
