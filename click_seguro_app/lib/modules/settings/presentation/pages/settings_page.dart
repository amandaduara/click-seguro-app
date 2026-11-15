import 'dart:async';

import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/settings/domain/entities/account_summary_entity.dart';
import 'package:click_seguro_app/modules/settings/domain/entities/language_choice.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/account_state.dart';
import 'package:click_seguro_app/modules/settings/presentation/controller/settings_controller.dart';
import 'package:click_seguro_app/modules/settings/presentation/extensions/language_choice_presentation.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/alerts_switch_tile.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/language_sheet.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_scaffold.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_section.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Configurações (B8, specs/013-configuracoes) no estilo do redesign 2.0
/// (specs/024): voltar redondo, título grande e seções em cartões padrão. Com
/// conta, a lista inteira; sem conta, só o que não precisa de conta (R6 de
/// specs/014-acessibilidade).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final UserSessionService session = GetIt.instance<UserSessionService>();
    // Um controller só: se a sessão expira com a tela aberta, a lista do
    // visitante usa o idioma e a versão já carregados.
    return ChangeNotifierProvider<SettingsController>(
      create: (_) {
        final SettingsController controller =
            GetIt.instance<SettingsController>();
        unawaited(
          session.isAuthenticated
              ? controller.load()
              : controller.loadDeviceSettings(),
        );
        return controller;
      },
      child: ValueListenableBuilder<UserSessionStatus>(
        valueListenable: session.sessionStatus,
        builder: (context, status, _) => SettingsScaffold(
          title: AppStrings.settingsTitle.tr(),
          fallbackLocation: '/profile',
          children: status == UserSessionStatus.authenticated
              ? const [_AccountSettings()]
              : const [_GuestSettings()],
        ),
      ),
    );
  }
}

/// Sem conta: sem cartão, sem itens da conta, sem "Sair" e sem convite
/// (clarificação de 2026-10-15).
class _GuestSettings extends StatelessWidget {
  const _GuestSettings();

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = context.watch<SettingsController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReadingSection(controller: controller),
        _AboutSection(version: controller.appVersion),
      ],
    );
  }
}

class _AccountSettings extends StatelessWidget {
  const _AccountSettings();

  /// "Dados pessoais" abre a edição por cima das Configurações (o cartão
  /// "Editar perfil" saiu, a pedido da usuária: abria a mesma tela); ao
  /// voltar, a conta recarrega.
  Future<void> _openProfileEdit(
    BuildContext context,
    SettingsController controller,
  ) async {
    await context.push<void>('/profile/edit');
    unawaited(controller.retryAccount());
  }

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = context.watch<SettingsController>();
    final AccountSummaryEntity? account = switch (controller.account) {
      AccountLoaded(:final account) => account,
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSection(
          title: AppStrings.settingsSectionAccount.tr(),
          children: [
            SettingsTile(
              icon: LucideIcons.userRound,
              title: AppStrings.settingsPersonalData.tr(),
              subtitle: AppStrings.settingsPersonalDataSub.tr(),
              onTap: () => _openProfileEdit(context, controller),
            ),
            SettingsTile(
              icon: LucideIcons.lockKeyhole,
              title: AppStrings.settingsChangePassword.tr(),
              subtitle: AppStrings.settingsChangePasswordSub.tr(),
              onTap: () => context.push('/settings/security'),
            ),
          ],
        ),
        SettingsSection(
          title: AppStrings.settingsSectionAlerts.tr(),
          children: [
            AlertsSwitchTile(
              value: account?.receiveNotifications,
              saving: controller.isSavingAlerts,
              // A falha fica na própria linha (aviso e ícone de tentar de
              // novo), sem SnackBar.
              loadFailed: controller.alertsLoadFailed,
              saveFailed: controller.alertsSaveFailed,
              retrying: controller.isRetryingAlerts,
              onChanged: controller.setReceiveAlerts,
              onRetry: controller.retryAlerts,
            ),
          ],
        ),
        _ReadingSection(controller: controller),
        _AboutSection(version: controller.appVersion),
        const SizedBox(height: AppSpacing.s7),
        SettingsCard(
          children: [
            SettingsTile(
              icon: LucideIcons.logOut,
              title: AppStrings.settingsLogout.tr(),
              destructive: true,
              onTap: controller.logout,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
          child: Text(
            AppStrings.settingsLogoutNote.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: AppTypography.caption.fontSize,
              height: 1.4,
              color: context.colors.textMutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Leitura e aparência": Acessibilidade e Idioma, com ou sem conta.
class _ReadingSection extends StatelessWidget {
  const _ReadingSection({required this.controller});

  final SettingsController controller;

  /// Troca o idioma na hora (RF-042). "Idioma do celular" apaga o idioma
  /// guardado pelo easy_localization, para a próxima abertura seguir o
  /// aparelho de novo.
  Future<void> _chooseLanguage(BuildContext context) async {
    final LanguageChoice? choice = await showLanguageSheet(
      context,
      current: controller.language,
    );
    if (choice == null || !context.mounted) return;
    await context.setLocale(choice.localeFor(context.deviceLocale));
    if (choice == LanguageChoice.device && context.mounted) {
      await context.deleteSaveLocale();
    }
    await controller.setLanguage(choice);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: AppStrings.settingsSectionReading.tr(),
      children: [
        SettingsTile(
          icon: LucideIcons.type,
          title: AppStrings.settingsAccessibility.tr(),
          subtitle: AppStrings.settingsAccessibilitySub.tr(),
          onTap: () => context.push('/settings/accessibility'),
        ),
        SettingsTile(
          icon: LucideIcons.globe,
          title: AppStrings.settingsLanguage.tr(),
          value: controller.language.label,
          onTap: () => _chooseLanguage(context),
        ),
      ],
    );
  }
}

/// "Sobre": Privacidade e Sobre o Click Seguro com a versão, com ou sem conta.
class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.version});

  /// Versão instalada; `null` até carregar.
  final String? version;

  @override
  Widget build(BuildContext context) {
    final String? version = this.version;
    return SettingsSection(
      title: AppStrings.settingsSectionAbout.tr(),
      children: [
        SettingsTile(
          icon: LucideIcons.shield,
          title: AppStrings.settingsPrivacy.tr(),
          subtitle: AppStrings.settingsPrivacySub.tr(),
          onTap: () => context.push('/settings/privacy'),
        ),
        SettingsTile(
          icon: LucideIcons.info,
          title: AppStrings.settingsAboutApp.tr(),
          subtitle: version == null || version.isEmpty
              ? null
              : AppStrings.settingsVersion.tr(args: [version]),
          onTap: () => context.push('/settings/about'),
        ),
      ],
    );
  }
}
