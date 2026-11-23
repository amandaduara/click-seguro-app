import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_listen_button.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_scaffold.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_topic_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Termos de uso (specs/026 FR-001 a FR-003), no molde da Privacidade. Abre
/// pelas Configurações e pelo aceite do cadastro, também sem sessão.
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  static const List<(IconData, String, String)> _topics = [
    (
      LucideIcons.info,
      AppStrings.settingsTermsAboutTitle,
      AppStrings.settingsTermsAboutBody,
    ),
    (
      LucideIcons.triangleAlert,
      AppStrings.settingsTermsLimitsTitle,
      AppStrings.settingsTermsLimitsBody,
    ),
    (
      LucideIcons.keyRound,
      AppStrings.settingsTermsAccountTitle,
      AppStrings.settingsTermsAccountBody,
    ),
    (
      LucideIcons.circleCheck,
      AppStrings.settingsTermsUseTitle,
      AppStrings.settingsTermsUseBody,
    ),
    (
      LucideIcons.shieldCheck,
      AppStrings.settingsTermsDataTitle,
      AppStrings.settingsTermsDataBody,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return SettingsScaffold(
      title: AppStrings.settingsTerms.tr(),
      children: [
        SettingsListenButton(text: termsSpokenText()),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s4),
          child: Text(
            AppStrings.settingsTermsUpdated.tr(),
            style: AppTypography.caption.copyWith(
              color: colors.textMutedForeground,
            ),
          ),
        ),
        for (final (icon, title, body) in _topics)
          SettingsTopicCard(
            icon: icon,
            title: title.tr(),
            body: body.tr(),
            // "Seus dados" leva à Privacidade.
            child: title == AppStrings.settingsTermsDataTitle
                ? const _SeePrivacyLink()
                : null,
          ),
      ],
    );
  }
}

/// O que o "Ouvir" dos Termos lê: título, data e cada assunto (título e
/// texto), com os mesmos textos traduzidos da tela.
String termsSpokenText() => [
  AppStrings.settingsTerms.tr(),
  AppStrings.settingsTermsUpdated.tr(),
  for (final (_, title, body) in TermsPage._topics) ...[title.tr(), body.tr()],
].join('\n');

class _SeePrivacyLink extends StatelessWidget {
  const _SeePrivacyLink();

  @override
  Widget build(BuildContext context) {
    final Color color = context.colors.primaryPressed;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s1),
      child: TextButton.icon(
        onPressed: () => context.push('/settings/privacy'),
        iconAlignment: IconAlignment.end,
        icon: Icon(LucideIcons.chevronRight, size: 18, color: color),
        label: Text(AppStrings.settingsTermsSeePrivacy.tr()),
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(48, 48),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: AppTypography.body.copyWith(
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
