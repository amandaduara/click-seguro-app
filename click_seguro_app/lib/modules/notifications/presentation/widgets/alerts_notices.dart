import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_offline_banner.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Faixas fixas no alto da tela de alertas, no lugar de avisos que somem
/// sozinhos (R12 de specs/011-alertas-locais).
class AlertsNotices extends StatelessWidget {
  const AlertsNotices({
    super.key,
    required this.showOffline,
    required this.showDisabled,
    required this.onOpenSettings,
  });

  /// Onde se liga "Receber alertas": a chave das Configurações
  /// (specs/013-configuracoes), por caminho, sem importar `settings`.
  static const String settingsRoute = '/settings';

  /// A última conferência falhou por falta de conexão.
  final bool showOffline;

  /// "Receber alertas" está desligado na conta.
  final bool showDisabled;

  /// Abre as Configurações; a tela confere de novo na volta.
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    if (!showOffline && !showDisabled) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showOffline) const SafeOfflineBanner(),
        if (showDisabled) _DisabledNotice(onOpenSettings: onOpenSettings),
      ],
    );
  }
}

/// Aviso de alertas desligados, com o caminho para ligar de volta.
class _DisabledNotice extends StatelessWidget {
  const _DisabledNotice({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        color: context.colors.warning.withValues(alpha: 0.1),
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.bellOff,
                  size: 20,
                  color: context.colors.warning,
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Text(
                    AppStrings.notificationsDisabledNotice.tr(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      color: context.colors.textForeground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            SafeButton(
              label: AppStrings.notificationsDisabledAction.tr(),
              tone: SafeButtonTone.secondary,
              onPressed: onOpenSettings,
            ),
          ],
        ),
      ),
    );
  }
}
