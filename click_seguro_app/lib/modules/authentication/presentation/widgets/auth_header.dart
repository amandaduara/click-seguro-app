import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/app_logo.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Logo oficial + "Bem-vindo ao / Click Seguro" (redesign 2.0, quadro
/// "03 Entrar"): selo rosado de canto 20 e o nome no tamanho de título de
/// tela.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        header: true,
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
              child: const AppLogo(size: 44),
            ),
            const SizedBox(width: AppSpacing.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.authWelcome.tr(),
                    style: AppTypography.body.copyWith(
                      color: context.colors.textMutedForeground,
                      height: 1.3,
                    ),
                  ),
                  Text(
                    AppStrings.authBrand.tr(),
                    style: AppTypography.display.copyWith(
                      color: context.colors.textForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
