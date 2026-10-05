import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Estado de erro (FR-015): a mensagem (já traduzida, ex.:
/// `failure.message.tr()`) e "Tentar novamente".
class SafeErrorState extends StatelessWidget {
  const SafeErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.circleAlert,
              size: 40,
              color: AppColors.destructive,
            ),
            const SizedBox(height: AppSpacing.s3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                color: AppColors.textForeground,
              ),
            ),
            const SizedBox(height: AppSpacing.s5),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: SafeButton(
                label: AppStrings.commonTryAgain.tr(),
                size: SafeButtonSize.compact,
                icon: const Icon(LucideIcons.rotateCcw),
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
