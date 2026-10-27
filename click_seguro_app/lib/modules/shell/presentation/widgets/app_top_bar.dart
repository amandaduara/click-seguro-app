import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
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

  Future<void> _openAssistant() async {
    if (await requireAccount(context) && mounted) await _open('/assistant');
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
      child: Builder(
        builder: (context) {
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // O nome muda também quando o perfil é editado (SC-003).
              ListenableBuilder(
                listenable: Listenable.merge([
                  _session.sessionStatus,
                  _session.profileVersion,
                ]),
                builder: (context, _) => Text(
                  widget.subtitle ?? _greeting(),
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textMutedForeground,
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
                    color: context.colors.secondary,
                  ),
                ),
              ),
            ],
          );
          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              NotificationBellButton(onPressed: _openNotifications),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.s2),
                child: _CircleActionButton(
                  label: AppStrings.assistantTitle.tr(),
                  icon: LucideIcons.messageCircle,
                  onPressed: _openAssistant,
                ),
              ),
              // Também para o visitante, que ajusta acessibilidade e idioma
              // (specs/014, R6).
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.s2),
                child: _CircleActionButton(
                  label: AppStrings.shellSettings.tr(),
                  icon: LucideIcons.settings,
                  onPressed: () => _open('/settings'),
                ),
              ),
            ],
          );
          final compact = MediaQuery.textScalerOf(context).scale(24) > 30;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                title,
                const SizedBox(height: AppSpacing.s2),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: AppSpacing.s2),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: context.colors.input,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 48,
              child: Icon(icon, size: 20, color: context.colors.secondary),
            ),
          ),
        ),
      ),
    );
  }
}
