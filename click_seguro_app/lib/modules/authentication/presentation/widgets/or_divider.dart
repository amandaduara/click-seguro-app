import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
          child: Text(
            AppStrings.authOr.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMutedForeground,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}
