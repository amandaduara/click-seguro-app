import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/modules/notifications/presentation/extensions/alert_presentation_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Resumo fixo no alto da tela ("Você tem 3 alertas novos") e, havendo não
/// lidos, o botão "Marcar todos como lidos", fora da lista que rola (R12 de
/// specs/011-alertas-locais).
class AlertsSummaryBar extends StatelessWidget {
  const AlertsSummaryBar({
    super.key,
    required this.unreadCount,
    required this.onMarkAll,
  });

  final int unreadCount;

  /// Sem confirmação: não é ação destrutiva.
  final VoidCallback onMarkAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s4,
        AppSpacing.s5,
        AppSpacing.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              summaryText(unreadCount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.colors.secondary,
              ),
            ),
          ),
          if (unreadCount > 0) ...[
            const SizedBox(height: AppSpacing.s3),
            SafeButton(
              label: AppStrings.notificationsMarkAll.tr(),
              onPressed: onMarkAll,
            ),
          ],
        ],
      ),
    );
  }
}
