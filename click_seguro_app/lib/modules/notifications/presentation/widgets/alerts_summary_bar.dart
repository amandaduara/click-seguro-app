import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/notifications/presentation/extensions/alert_presentation_extension.dart';
import 'package:flutter/material.dart';

/// Resumo fixo no alto da tela ("Você tem 3 alertas novos"), fora da lista
/// que rola (R12 de specs/011-alertas-locais).
class AlertsSummaryBar extends StatelessWidget {
  const AlertsSummaryBar({super.key, required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s4,
        AppSpacing.s5,
        AppSpacing.s3,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
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
      ),
    );
  }
}
