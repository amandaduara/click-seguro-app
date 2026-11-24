import 'package:click_seguro_app/core/constants/app_identity.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/app_logo.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/modules/common/services/app_info_service.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_listen_button.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_scaffold.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// O que o "Ouvir" do Sobre lê: título, nome, versão (quando já se sabe),
/// objetivo e crédito, com os mesmos textos traduzidos da tela.
String aboutSpokenText({String version = ''}) => [
  AppStrings.settingsAboutApp.tr(),
  AppIdentity.name,
  if (version.isNotEmpty) AppStrings.settingsVersion.tr(args: [version]),
  AppStrings.settingsAboutGoal.tr(),
  AppStrings.settingsAboutCredits.tr(),
].join('\n');

/// "Sobre o Click Seguro" (FR-023): nome, objetivo, versão instalada e o
/// crédito genérico do TCC.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final Future<String> _version = GetIt.instance<AppInfoService>()
      .version();

  /// A versão, quando chega, entra no que o "Ouvir" lê.
  String _loadedVersion = '';

  @override
  void initState() {
    super.initState();
    // Sem versão (falha), lê o resto, como a tela mostra.
    _version.then<void>((version) {
      if (mounted) setState(() => _loadedVersion = version);
    }, onError: (Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SettingsScaffold(
      title: AppStrings.settingsAboutApp.tr(),
      children: [
        SettingsListenButton(text: aboutSpokenText(version: _loadedVersion)),
        const SizedBox(height: AppSpacing.s6),
        SafeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: AppLogo(size: 88)),
              const SizedBox(height: AppSpacing.s3),
              Text(
                AppIdentity.name,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontSize: AppTypography.title1.fontSize,
                  fontWeight: FontWeight.w800,
                  color: colors.secondary,
                ),
              ),
              FutureBuilder<String>(
                future: _version,
                builder: (context, snapshot) {
                  final String version = snapshot.data ?? '';
                  return version.isEmpty
                      ? const SizedBox(height: AppSpacing.s4)
                      : Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.s1),
                          child: Text(
                            AppStrings.settingsVersion.tr(args: [version]),
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: AppTypography.caption.fontSize,
                              color: colors.textMutedForeground,
                            ),
                          ),
                        );
                },
              ),
              const SizedBox(height: AppSpacing.s5),
              Text(
                AppStrings.settingsAboutGoal.tr(),
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  fontSize: AppTypography.body.fontSize,
                  height: 1.5,
                  color: colors.textBody,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        Text(
          AppStrings.settingsAboutCredits.tr(),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: AppTypography.caption.fontSize,
            color: colors.textMutedForeground,
          ),
        ),
      ],
    );
  }
}
