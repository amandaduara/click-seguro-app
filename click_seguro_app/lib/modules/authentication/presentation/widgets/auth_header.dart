import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/app_logo.dart';
import 'package:click_seguro_app/modules/authentication/presentation/widgets/login_intro.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Cabeçalho do login e do cadastro na versão A (specs/026 FR-011): a marca
/// coral pequena, "Bem-vindo ao Click Seguro" e o slogan da splash,
/// centralizados, como o fim da splash em tamanho menor.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  /// Largura da marca no cabeçalho.
  static const double _logoSize = 68;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return MergeSemantics(
      child: Semantics(
        header: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: LoginIntroLogoSlot(child: AppLogo(size: _logoSize)),
            ),
            const SizedBox(height: AppSpacing.s3),
            LoginIntroReveal(
              step: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.authWelcomeTitle.tr(),
                    textAlign: TextAlign.center,
                    // Título 1 (24): cabe numa linha e deixa o login inteiro
                    // caber na tela, com a onda no pé (validação 2026-11-23).
                    style: AppTypography.title1.copyWith(
                      color: colors.textForeground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    AppStrings.splashTagline.tr(),
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(color: colors.textBody),
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
