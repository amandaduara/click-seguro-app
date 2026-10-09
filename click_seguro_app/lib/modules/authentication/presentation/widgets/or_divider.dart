import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: context.colors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
          child: Text(
            AppStrings.authOr.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textMutedForeground,
            ),
          ),
        ),
        Expanded(child: Divider(color: context.colors.border)),
      ],
    );
  }
}
