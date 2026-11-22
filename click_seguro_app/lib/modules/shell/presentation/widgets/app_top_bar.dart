import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_icon_button.dart';
import 'package:click_seguro_app/modules/notifications/notifications.dart';
import 'package:click_seguro_app/modules/shell/presentation/require_account.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Barra superior das abas Início, Atividades e Ajuda (design system §7.11).
///
/// Cada página a coloca no próprio topo (R6 de specs/005-shell-navegacao-base).
/// Com [subtitle] (a saudação do Início), ele fica na linha dos botões e o
/// título embaixo; sem ele, o título divide a linha com os botões. Só o
/// Início cumprimenta (validação da usuária, specs/024).
class AppTopBar extends StatefulWidget {
  const AppTopBar({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  State<AppTopBar> createState() => _AppTopBarState();
}

class _AppTopBarState extends State<AppTopBar> {
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

  @override
  Widget build(BuildContext context) {
    final Widget actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NotificationBellButton(onPressed: _openNotifications),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.s2),
          child: Tooltip(
            message: AppStrings.assistantTitle.tr(),
            child: SafeIconButton(
              icon: LucideIcons.messageCircle,
              semanticLabel: AppStrings.assistantTitle.tr(),
              onPressed: _openAssistant,
            ),
          ),
        ),
      ],
    );
    final Widget title = Semantics(
      header: true,
      child: Text(
        widget.title,
        style: AppTypography.display.copyWith(
          color: context.colors.textForeground,
        ),
      ),
    );
    final String? subtitle = widget.subtitle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s4,
        AppSpacing.s5,
        AppSpacing.s4,
      ),
      child: subtitle == null
          ? Row(
              children: [
                Expanded(child: title),
                const SizedBox(width: AppSpacing.s2),
                actions,
              ],
            )
          // Início: a saudação e os botões na primeira linha; o título
          // embaixo, grande e inteiro, sem dividir espaço com os botões.
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // A saudação pela base da linha dos botões, colada ao título
                // logo abaixo (validação da usuária).
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: AppTypography.body.copyWith(
                          color: context.colors.textMutedForeground,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    actions,
                  ],
                ),
                const SizedBox(height: AppSpacing.s1),
                title,
              ],
            ),
    );
  }
}
