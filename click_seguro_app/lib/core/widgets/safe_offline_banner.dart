import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Faixa de sem internet, no topo do conteúdo guardado (FR-015).
class SafeOfflineBanner extends StatelessWidget {
  const SafeOfflineBanner({super.key, this.showsSavedContent = true});

  /// `false` quando a tela não tem nada guardado para mostrar: a faixa diz só
  /// que está sem internet (specs/027 FR-011).
  final bool showsSavedContent;

  /// Canto da faixa: entre o `radiusSm` (12) e o `radiusMd` (16).
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(14));

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s5,
          vertical: AppSpacing.s2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        decoration: BoxDecoration(
          color: colors.secondary,
          borderRadius: _radius,
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.wifiOff,
              size: 22,
              color: colors.textPrimaryForeground,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                (showsSavedContent
                        ? AppStrings.commonOfflineBanner
                        : AppStrings.commonOfflineBannerShort)
                    .tr(),
                style: AppTypography.label.copyWith(
                  color: colors.textPrimaryForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
