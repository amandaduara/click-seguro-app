import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Corpo das telas que a trilha ainda não construiu (FR-006).
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.hourglass,
              size: 40,
              color: context.colors.textMutedForeground,
            ),
            const SizedBox(height: AppSpacing.s4),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: context.colors.secondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              AppStrings.commonComingSoon.tr(),
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: context.colors.textMutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
