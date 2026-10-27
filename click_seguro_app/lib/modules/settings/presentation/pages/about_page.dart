import 'package:click_seguro_app/core/constants/app_identity.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/common/services/app_info_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// "Sobre o SafeNews" (FR-023): nome, objetivo, versão instalada e o
/// crédito genérico do TCC.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final Future<String> _version = GetIt.instance<AppInfoService>()
      .version();

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.settingsAboutApp.tr())),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s6),
          children: [
            Icon(LucideIcons.shieldCheck, size: 56, color: colors.primary),
            const SizedBox(height: AppSpacing.s3),
            Semantics(
              header: true,
              child: Text(
                AppIdentity.name,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: colors.secondary,
                ),
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
                            fontSize: 14,
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
                fontSize: 16,
                height: 1.5,
                color: colors.textForeground,
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            Text(
              AppStrings.settingsAboutCredits.tr(),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: colors.textMutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
