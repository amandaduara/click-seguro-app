import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Estado de carregando (FR-015), com texto opcional já traduzido.
class SafeLoadingState extends StatelessWidget {
  const SafeLoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final String? text = message;
    return Center(
      child: Semantics(
        liveRegion: true,
        label: AppStrings.commonLoading.tr(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              if (text != null) ...[
                const SizedBox(height: AppSpacing.s3),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    color: AppColors.textMutedForeground,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
