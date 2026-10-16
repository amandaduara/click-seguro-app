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
import 'package:click_seguro_app/modules/settings/presentation/widgets/account_card.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/alerts_switch_tile.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/language_sheet.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_section.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Configurações (B8, specs/013-configuracoes), no quadro do Figma. Com
/// conta, a lista inteira; sem conta, só o que não precisa de conta (R6 de
/// specs/014-acessibilidade).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final UserSessionService session = GetIt.instance<UserSessionService>();
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.settingsTitle.tr())),
      body: SafeArea(
        // Um controller só: se a sessão expira com a tela aberta, a lista do
        // visitante usa o idioma e a versão já carregados.
        child: ChangeNotifierProvider<SettingsController>(
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
            builder: (context, status, _) =>
                status == UserSessionStatus.authenticated
                ? _SettingsList(sessionName: session.userName ?? '')
                : const _GuestSettingsList(),
          ),
        ),
      ),
    );
  }
}

const EdgeInsets _listPadding = EdgeInsets.fromLTRB(
  AppSpacing.s5,
  AppSpacing.s4,
  AppSpacing.s5,
  AppSpacing.s6,
);

/// Sem conta: sem cartão, sem itens da conta, sem "Sair" e sem convite
/// (clarificação de 2026-10-15).
class _GuestSettingsList extends StatelessWidget {
  const _GuestSettingsList();

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = context.watch<SettingsController>();
    return ListView(
      padding: _listPadding,
      children: [
        _ReadingSection(controller: controller),
        _AboutSection(version: controller.appVersion),
      ],
    );
  }
}

class _SettingsList extends StatelessWidget {
  const _SettingsList({required this.sessionName});

  /// Nome guardado na sessão: o cartão o usa enquanto a conta não chega ou
  /// se ela não carregar.
  final String sessionName;

  Future<void> _openPersonalData(
    BuildContext context,
    SettingsController controller,
  ) async {
    await context.push<void>('/profile/edit');
    unawaited(controller.retryAccount());
  }

  Future<void> _setAlerts(
    BuildContext context,
    SettingsController controller,
    bool value,
  ) async {
    final failure = await controller.setReceiveAlerts(value);
    if (failure == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppStrings.settingsAlertsFailed.tr())),
      );
  }

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = context.watch<SettingsController>();
    final AccountSummaryEntity? account = switch (controller.account) {
      AccountLoaded(:final account) => account,
      _ => null,
    };
    final String name = account?.name ?? sessionName;
    return ListView(
      padding: _listPadding,
      children: [
        AccountCard(
          name: name,
          initials: initialsOf(name),
          avatarUrl: account?.avatarUrl,
          onTap: () => context.go('/profile'),
        ),
        SettingsSection(
          title: AppStrings.settingsSectionAccount.tr(),
          children: [
            SettingsTile(
              icon: LucideIcons.userRound,
              title: AppStrings.settingsPersonalData.tr(),
              subtitle: AppStrings.settingsPersonalDataSub.tr(),
              onTap: () => _openPersonalData(context, controller),
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
              onChanged: (value) => _setAlerts(context, controller, value),
              onRetry: controller.retryAccount,
            ),
          ],
        ),
        _ReadingSection(controller: controller),
        _AboutSection(version: controller.appVersion),
        const SizedBox(height: AppSpacing.s6),
        _LogoutButton(onPressed: controller.logout),
        const SizedBox(height: AppSpacing.s3),
        Text(
          AppStrings.settingsLogoutNote.tr(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: context.colors.textMutedForeground,
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

/// "Sobre": Privacidade e Sobre o SafeNews com a versão, com ou sem conta.
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

/// "Sair da conta": contorno e texto vermelhos; sai na hora, sem aviso
/// (clarificação de 2026-10-14).
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: colors.destructive,
        backgroundColor: colors.destructive.withValues(alpha: 0.06),
        side: BorderSide(color: colors.destructive.withValues(alpha: 0.5)),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.radiusFull,
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      icon: const Icon(LucideIcons.logOut, size: 20),
      label: Text(AppStrings.settingsLogout.tr()),
    );
  }
}
