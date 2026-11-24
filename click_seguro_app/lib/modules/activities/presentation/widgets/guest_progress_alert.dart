import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// O que o visitante escolheu no aviso; `null` (voltar) vale como continuar.
enum GuestAlertAction { createAccount, continueWithoutAccount }

/// Aviso antes da conclusão, só para quem está sem conta (RF-030, RN-006).
/// Não chama a rede; a leitura automática fica com a `LessonPage` (R3 de
/// specs/020).
Future<GuestAlertAction?> showGuestProgressAlert(BuildContext context) =>
    showModalBottomSheet<GuestAlertAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: context.colors.card,
      builder: (sheetContext) {
        final TextTheme textTheme = Theme.of(sheetContext).textTheme;
        return SingleChildScrollView(
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
                  AppStrings.activitiesGuestAlertTitle.tr(),
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: sheetContext.colors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                AppStrings.activitiesGuestAlertBody.tr(),
                style: textTheme.bodyLarge?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.s5),
              SafeButton(
                label: AppStrings.activitiesGuestAlertCreate.tr(),
                onPressed: () => Navigator.of(
                  sheetContext,
                ).pop(GuestAlertAction.createAccount),
              ),
              const SizedBox(height: AppSpacing.s3),
              SafeButton(
                label: AppStrings.activitiesGuestAlertContinue.tr(),
                tone: SafeButtonTone.secondary,
                onPressed: () => Navigator.of(
                  sheetContext,
                ).pop(GuestAlertAction.continueWithoutAccount),
              ),
            ],
          ),
        );
      },
    );
