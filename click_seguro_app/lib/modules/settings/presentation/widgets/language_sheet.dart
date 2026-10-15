import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/settings/domain/entities/language_choice.dart';
import 'package:click_seguro_app/modules/settings/presentation/extensions/language_choice_presentation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Idioma do celular, Português ou English, com a escolha atual marcada.
Future<LanguageChoice?> showLanguageSheet(
  BuildContext context, {
  required LanguageChoice current,
}) => showModalBottomSheet<LanguageChoice>(
  context: context,
  showDragHandle: true,
  builder: (sheetContext) {
    final AppPalette colors = sheetContext.colors;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final choice in LanguageChoice.values)
            ListTile(
              minTileHeight: 56,
              selected: choice == current,
              title: Text(choice.label, style: const TextStyle(fontSize: 16)),
              trailing: choice == current
                  ? Icon(LucideIcons.check, color: colors.primary)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(choice),
            ),
          const SizedBox(height: AppSpacing.s2),
        ],
      ),
    );
  },
);
