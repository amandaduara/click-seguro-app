import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Aviso no lugar de uma área que não carregou (US1, cenário 9), com
/// "Tentar novamente".
class AreaNotice extends StatelessWidget {
  const AreaNotice({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppSpacing.radius2xl,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.circleAlert,
                size: 20,
                color: colors.destructive,
              ),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    color: colors.textForeground,
                  ),
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: colors.primary,
            ),
            icon: const Icon(LucideIcons.rotateCcw, size: 18),
            label: Text(AppStrings.commonTryAgain.tr()),
          ),
        ],
      ),
    );
  }
}
