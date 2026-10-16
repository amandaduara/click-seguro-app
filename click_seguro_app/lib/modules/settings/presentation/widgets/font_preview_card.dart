import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Um trecho de notícia para a pessoa comparar os tamanhos de letra. Não tem
/// escala própria: cresce junto com o app, que muda na hora (R2 de
/// specs/014-acessibilidade).
class FontPreviewCard extends StatelessWidget {
  const FontPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppSpacing.radius2xl,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.settingsAccessibilityPreviewTitle.tr(),
              style: textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s1),
            Text(
              AppStrings.settingsAccessibilityPreviewBody.tr(),
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                color: colors.textForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
