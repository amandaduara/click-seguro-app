import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/notifications/notifications.dart';
import 'package:click_seguro_app/modules/shell/presentation/require_account.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Barra superior das abas Início, Atividades e Ajuda (design system §7.11).
///
/// Cada página a coloca no próprio topo, para poder trocar o [subtitle] sem
/// mexer no shell (R6 de specs/005-shell-navegacao-base). Sem [subtitle],
/// cumprimenta pelo nome ou dá as boas-vindas ao visitante.
class AppTopBar extends StatefulWidget {
  const AppTopBar({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  State<AppTopBar> createState() => _AppTopBarState();
}

class _AppTopBarState extends State<AppTopBar> {
  final UserSessionService _session = GetIt.instance<UserSessionService>();

  /// Evita abrir a mesma tela duas vezes com toque duplo.
  bool _opening = false;

  Future<void> _open(String location) async {
    if (_opening) return;
    _opening = true;
    try {
      await context.push(location);
    } finally {
      if (mounted) _opening = false;
    }
  }

  /// Alertas exigem conta (RN-003): visitante vê o convite (FR-012).
  Future<void> _openNotifications() async {
    if (await requireAccount(context) && mounted) await _open('/notifications');
  }

  String _greeting() {
    final String? name = _session.userName;
    return _session.isAuthenticated && name != null && name.isNotEmpty
        ? AppStrings.shellGreeting.tr(args: [name])
        : AppStrings.shellWelcome.tr();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s6,
        AppSpacing.s5,
        AppSpacing.s3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<UserSessionStatus>(
                  valueListenable: _session.sessionStatus,
                  builder: (context, _, _) => Text(
                    widget.subtitle ?? _greeting(),
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMutedForeground,
                    ),
                  ),
                ),
                Semantics(
                  header: true,
                  child: Text(
                    widget.title,
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          NotificationBellButton(onPressed: _openNotifications),
          const SizedBox(width: AppSpacing.s2),
          _SettingsButton(onPressed: () => _open('/settings')),
        ],
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppStrings.shellSettings.tr(),
      excludeSemantics: true,
      child: Material(
        color: AppColors.input,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              LucideIcons.settings,
              size: 20,
              color: AppColors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
