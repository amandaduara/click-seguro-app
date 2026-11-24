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
                  _LanguageOption(
                    label: choice.label,
                    selected: choice == current,
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

/// Uma linha da folha: o nome do idioma ocupa o espaço livre e o sinal de
/// escolhido fica no fim da linha, à direita, num espaço sempre reservado
/// (o nome não muda de lugar ao escolher).
class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.body.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: colors.textForeground,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                SizedBox.square(
                  dimension: 24,
                  child: selected
                      ? Icon(LucideIcons.check, color: colors.success)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
