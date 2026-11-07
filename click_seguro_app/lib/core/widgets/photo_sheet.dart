import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Escolha na folha da foto.
enum PhotoAction { gallery, camera, remove }

/// "Galeria", "Câmera" e, se já houver foto, "Remover foto".
Future<PhotoAction?> showPhotoSheet(
  BuildContext context, {
  required bool hasPhoto,
}) => showModalBottomSheet<PhotoAction>(
  context: context,
  showDragHandle: true,
  builder: (sheetContext) {
    final AppPalette colors = sheetContext.colors;
    Widget option(PhotoAction action, IconData icon, String label) => ListTile(
      minTileHeight: 56,
      leading: Icon(icon, color: colors.secondary),
      title: Text(label, style: const TextStyle(fontSize: 16)),
      onTap: () => Navigator.of(sheetContext).pop(action),
    );
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          option(
            PhotoAction.gallery,
            LucideIcons.image,
            AppStrings.commonPhotoGallery.tr(),
          ),
          option(
            PhotoAction.camera,
            LucideIcons.camera,
            AppStrings.commonPhotoCamera.tr(),
          ),
          if (hasPhoto)
            option(
              PhotoAction.remove,
              LucideIcons.trash2,
              AppStrings.commonPhotoRemove.tr(),
            ),
          const SizedBox(height: AppSpacing.s2),
        ],
      ),
    );
  },
);

/// Sem acesso à galeria ou à câmera: como liberar (CB-010).
Future<void> showPhotoPermissionSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final TextTheme textTheme = Theme.of(sheetContext).textTheme;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s6,
              0,
              AppSpacing.s6,
              AppSpacing.s6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    AppStrings.commonPhotoPermissionTitle.tr(),
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: sheetContext.colors.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  AppStrings.commonPhotoPermissionBody.tr(),
                  style: textTheme.bodyLarge?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.s5),
                SafeButton(
                  label: AppStrings.commonPhotoPermissionOk.tr(),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
