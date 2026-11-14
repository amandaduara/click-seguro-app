import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/safe_sheet.dart';
import 'package:click_seguro_app/modules/settings/domain/entities/language_choice.dart';
import 'package:click_seguro_app/modules/settings/presentation/extensions/language_choice_presentation.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Idioma do celular, Português ou English, num cartão padrão, com a escolha
/// atual marcada.
Future<LanguageChoice?> showLanguageSheet(
  BuildContext context, {
  required LanguageChoice current,
}) => showModalBottomSheet<LanguageChoice>(
  context: context,
  builder: (sheetContext) {
    final AppPalette colors = sheetContext.colors;
    return SingleChildScrollView(
      child: SafeSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                AppStrings.settingsLanguage.tr(),
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                  fontSize: AppTypography.title2.fontSize,
                  fontWeight: FontWeight.w800,
                  color: colors.secondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            SettingsCard(
              children: [
                for (final choice in LanguageChoice.values)
                  ListTile(
                    minTileHeight: 56,
                    selected: choice == current,
                    selectedColor: colors.textForeground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s4,
                    ),
                    title: Text(
                      choice.label,
                      style: TextStyle(
                        fontSize: AppTypography.body.fontSize,
                        fontWeight: choice == current
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: choice == current
                        ? Icon(LucideIcons.check, color: colors.success)
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(choice),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);
