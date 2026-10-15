import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/common/accessibility/accessibility_preferences.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/accessibility_controller.dart';
import 'package:click_seguro_app/modules/settings/presentation/extensions/accessibility_presentation.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/font_preview_card.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_option_tile.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_section.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_switch_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Tela de Acessibilidade (B9, specs/014-acessibilidade). Cada escolha vale na
/// hora e fica guardada pelo [AccessibilityController] da feature 009.
class AccessibilityPage extends StatelessWidget {
  const AccessibilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AccessibilityController controller = context
        .watch<AccessibilityController>();
    final AccessibilityPreferences preferences = controller.preferences;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.settingsAccessibilityTitle.tr())),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s5,
            AppSpacing.s4,
            AppSpacing.s5,
            AppSpacing.s6,
          ),
          children: [
            // Título, prévia e opções em sequência: a prévia fica fora do
            // cartão das opções.
            SettingsSectionTitle(
              AppStrings.settingsAccessibilitySectionFont.tr(),
            ),
            const FontPreviewCard(),
            const SizedBox(height: AppSpacing.s3),
            RadioGroup<FontScaleLevel>(
              groupValue: preferences.fontScale,
              onChanged: (level) => controller.setFontScale(level!),
              child: SettingsCard(
                children: [
                  for (final FontScaleLevel level in FontScaleLevel.values)
                    SettingsOptionTile<FontScaleLevel>(
                      value: level,
                      title: level.label,
                      trailingText: level.percentLabel,
                    ),
                ],
              ),
            ),
            SettingsSection(
              title: AppStrings.settingsAccessibilitySectionAppearance.tr(),
              children: [
                SettingsSwitchTile(
                  icon: LucideIcons.contrast,
                  title: AppStrings.settingsAccessibilityHighContrast.tr(),
                  subtitle: AppStrings.settingsAccessibilityHighContrastSub
                      .tr(),
                  value: preferences.highContrast,
                  onChanged: controller.setHighContrast,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
