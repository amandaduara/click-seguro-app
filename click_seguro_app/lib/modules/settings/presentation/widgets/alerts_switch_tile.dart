import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_switch_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// "Alertas de notícias novas" com a chave (FR-016). [value] nulo = a conta
/// não carregou: a chave fica parada e aparece "Tentar novamente".
class AlertsSwitchTile extends StatelessWidget {
  const AlertsSwitchTile({
    super.key,
    required this.value,
    required this.saving,
    required this.onChanged,
    required this.onRetry,
  });

  final bool? value;
  final bool saving;
  final ValueChanged<bool> onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final bool? current = value;
    final bool enabled = current != null && !saving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSwitchTile(
          icon: LucideIcons.bell,
          title: AppStrings.settingsAlerts.tr(),
          subtitle: current == null
              ? AppStrings.settingsAccountLoadFailed.tr()
              : AppStrings.settingsAlertsSub.tr(),
          value: current ?? false,
          onChanged: enabled ? onChanged : null,
        ),
        if (current == null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: colors.primary,
              ),
              child: Text(AppStrings.commonTryAgain.tr()),
            ),
          ),
      ],
    );
  }
}
