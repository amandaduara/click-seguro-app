import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/modules/notifications/presentation/controller/notifications_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Sino da barra superior, com o número de alertas não lidos. Só desenha o
/// botão: quem decide se abre os alertas (convite para visitante) é o
/// `AppTopBar` do shell, para que este módulo não dependa do shell (R5 de
/// specs/005-shell-navegacao-base). O número vem do [NotificationsController]
/// do módulo (R7 de specs/011-alertas-locais).
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key, required this.onPressed});

  static const Key badgeKey = ValueKey('bell-badge');

  /// Círculo do número: maior que o do design system (10 sp), por legibilidade.
  static const double _badgeSize = 24;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final int unread = context.select<NotificationsController, int>(
      (controller) => controller.unreadCount,
    );
    return Semantics(
      button: true,
      label: _label(unread),
      excludeSemantics: true,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          children: [
            Material(
              color: context.colors.input,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    LucideIcons.bell,
                    size: 20,
                    color: context.colors.secondary,
                  ),
                ),
              ),
            ),
            if (unread > 0)
              Positioned(
                top: 0,
                right: 0,
                child: IgnorePointer(child: _Badge(count: unread)),
              ),
          ],
        ),
      ),
    );
  }

  static String _label(int unread) {
    if (unread == 0) return AppStrings.shellNotifications.tr();
    if (unread == 1) return AppStrings.notificationsBellLabelOne.tr();
    return AppStrings.notificationsBellLabel.tr(args: ['$unread']);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: NotificationBellButton.badgeKey,
      constraints: const BoxConstraints(
        minWidth: NotificationBellButton._badgeSize,
        minHeight: NotificationBellButton._badgeSize,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(NotificationBellButton._badgeSize),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 14,
          height: 1,
          fontWeight: FontWeight.bold,
          color: context.colors.textPrimaryForeground,
        ),
      ),
    );
  }
}
