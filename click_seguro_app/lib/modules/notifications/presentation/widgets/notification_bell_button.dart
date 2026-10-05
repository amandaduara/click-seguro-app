import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Sino da barra superior. Só desenha o botão: quem decide se abre os
/// alertas (convite para visitante) é o `AppTopBar` do shell, para que este
/// módulo não dependa do shell (R5 de specs/005-shell-navegacao-base).
///
/// A tarefa A6 acrescenta o contador de não lidos.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppStrings.shellNotifications.tr(),
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
            child: Icon(LucideIcons.bell, size: 20, color: AppColors.secondary),
          ),
        ),
      ),
    );
  }
}
