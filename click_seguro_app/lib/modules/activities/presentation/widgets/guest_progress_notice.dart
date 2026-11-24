import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Aviso do visitante: sem conta, o progresso vale até fechar o app, e criar
/// a conta leva o progresso junto (FR-010, clarificação de 2026-10-19).
class GuestProgressNotice extends StatelessWidget {
  const GuestProgressNotice({super.key});

  // Redesign 2.0: faixa creme compacta, com o convite como link (a ação
  // principal da tela continua sendo abrir um módulo).
  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppSpacing.radiusMd,
        border: colors.shadow.isEmpty ? Border.all(color: colors.border) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4,
          AppSpacing.s3,
          AppSpacing.s2,
          AppSpacing.s1,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: ExcludeSemantics(
                child: Icon(LucideIcons.info, size: 22, color: colors.info),
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.activitiesGuestNotice.tr(),
                    style: AppTypography.body.copyWith(
                      fontSize: 16,
                      height: 1.4,
                      color: colors.textForeground,
                    ),
                  ),
                  SafeButton(
                    label: AppStrings.activitiesGuestAction.tr(),
                    size: SafeButtonSize.compact,
                    tone: SafeButtonTone.link,
                    onPressed: () => context.go('/login'),
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
