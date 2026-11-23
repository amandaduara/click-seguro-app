import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_listen_button.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_scaffold.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_topic_card.dart';
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
        SettingsListenButton(text: privacySpokenText()),
        for (final (icon, title, body) in _sections)
          SettingsTopicCard(icon: icon, title: title.tr(), body: body.tr()),
      ],
    );
  }
}

/// O que o "Ouvir" da Privacidade lê: o título da tela e cada assunto
/// (título e texto), com os mesmos textos traduzidos da tela.
String privacySpokenText() => [
  AppStrings.settingsPrivacy.tr(),
  for (final (_, title, body) in PrivacyPage._sections) ...[
    title.tr(),
    body.tr(),
  ],
].join('\n');
