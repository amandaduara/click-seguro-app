import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Faixa de sem internet, no topo do conteúdo guardado (FR-015).
class SafeOfflineBanner extends StatelessWidget {
  const SafeOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: AppColors.warning.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.wifiOff, size: 20, color: AppColors.warning),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                AppStrings.commonOfflineBanner.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  color: AppColors.textForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
