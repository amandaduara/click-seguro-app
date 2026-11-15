import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_scaffold.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Como o app cuida dos dados (FR-022): o que fica no serviço e o que fica
/// só no celular (RN-007, RNF-008).
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  static const List<(IconData, String, String)> _sections = [
    (
      LucideIcons.cloud,
      AppStrings.settingsPrivacyAccountTitle,
      AppStrings.settingsPrivacyAccountBody,
    ),
    (
      LucideIcons.smartphone,
      AppStrings.settingsPrivacyDeviceTitle,
      AppStrings.settingsPrivacyDeviceBody,
    ),
    (
      LucideIcons.shieldCheck,
      AppStrings.settingsPrivacyUseTitle,
      AppStrings.settingsPrivacyUseBody,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: AppStrings.settingsPrivacy.tr(),
      children: [
        for (final (icon, title, body) in _sections)
          _Paragraph(icon: icon, title: title.tr(), body: body.tr()),
      ],
    );
  }
}

/// Um cartão padrão por assunto: ícone no círculo suave, título e o texto.
class _Paragraph extends StatelessWidget {
  const _Paragraph({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s5),
      child: SafeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SettingsIconCircle(icon: icon, color: colors.secondary),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: AppTypography.title3.fontSize,
                        fontWeight: FontWeight.w800,
                        color: colors.secondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            Text(
              body,
              style: textTheme.bodyLarge?.copyWith(
                fontSize: AppTypography.body.fontSize,
                height: 1.5,
                color: colors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
