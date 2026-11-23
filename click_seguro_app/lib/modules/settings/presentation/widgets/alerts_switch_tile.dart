import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_switch_tile.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// "Alertas de notícias novas" com a chave (FR-016). Se a conta não carregou
/// ([loadFailed]) ou salvar a escolha falhou ([saveFailed]), a chave dá lugar
/// ao ícone vermelho de tentar de novo. Enquanto salva ([saving]), tenta de
/// novo ([retrying]) ou a conta carrega, um carregamento ocupa o lugar da
/// chave (validação da usuária, specs/024).
class AlertsSwitchTile extends StatelessWidget {
  const AlertsSwitchTile({
    super.key,
    required this.value,
    required this.saving,
    required this.onChanged,
    required this.onRetry,
    this.loadFailed = false,
    this.saveFailed = false,
    this.failure,
    this.retrying = false,
  });

  static const Key retryKey = ValueKey('alerts-retry');

  /// Carregamento no lugar da chave: salvando, tentando de novo ou com a
  /// conta ainda carregando.
  static const Key busyKey = ValueKey('alerts-busy');

  /// `null` enquanto a conta não carregou.
  final bool? value;
  final bool saving;
  final bool loadFailed;
  final bool saveFailed;

  /// A falha de [loadFailed] ou [saveFailed]: sem internet, a linha diz a
  /// frase padrão (specs/027).
  final Failure? failure;
  final bool retrying;
  final ValueChanged<bool> onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final bool? current = value;
    if (retrying || loadFailed || saveFailed) {
      return SettingsTile(
        icon: LucideIcons.bell,
        title: AppStrings.settingsAlerts.tr(),
        subtitle: loadFailed || saveFailed
            ? failure
                  .messageKeyOr(
                    loadFailed
                        ? AppStrings.settingsAccountLoadFailed
                        : AppStrings.settingsAlertsFailed,
                  )
                  .tr()
            : AppStrings.settingsAlertsSub.tr(),
        onTap: retrying ? null : onRetry,
        trailing: retrying
            ? const _BusyIndicator()
            : _RetryButton(onPressed: onRetry),
      );
    }
    if (saving || current == null) {
      return SettingsTile(
        icon: LucideIcons.bell,
        title: AppStrings.settingsAlerts.tr(),
        subtitle: AppStrings.settingsAlertsSub.tr(),
        trailing: const _BusyIndicator(),
      );
    }
    return SettingsSwitchTile(
      icon: LucideIcons.bell,
      title: AppStrings.settingsAlerts.tr(),
      subtitle: AppStrings.settingsAlertsSub.tr(),
      value: current,
      onChanged: onChanged,
    );
  }
}

/// Ícone vermelho de reiniciar, com alvo de 48 dp. A ação para o leitor de
/// tela é a da linha (botão "…, Tentar de novo"): aqui só o rótulo entra na
/// leitura, sem uma segunda ação.
class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.settingsAlertsRetry.tr(),
      child: ExcludeSemantics(
        child: SizedBox.square(
          key: AlertsSwitchTile.retryKey,
          dimension: 48,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Icon(
                LucideIcons.rotateCcw,
                size: 26,
                color: context.colors.destructive,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Carregamento no mesmo espaço da chave, para a linha não pular.
class _BusyIndicator extends StatelessWidget {
  const _BusyIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: AlertsSwitchTile.busyKey,
      dimension: 48,
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: context.colors.primary,
            semanticsLabel: AppStrings.commonLoading.tr(),
          ),
        ),
      ),
    );
  }
}
