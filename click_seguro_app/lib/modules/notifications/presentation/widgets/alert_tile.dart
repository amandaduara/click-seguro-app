import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';
import 'package:click_seguro_app/modules/notifications/presentation/extensions/alert_presentation_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Um alerta na lista: "Novo" escrito (além da cor) quando não lido, título e
/// "fonte · hora/data". Cartão inteiro tocável, bem acima de 48 dp.
class AlertTile extends StatelessWidget {
  const AlertTile({
    super.key,
    required this.alert,
    required this.now,
    required this.onTap,
  });

  final AlertEntity alert;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool unread = !alert.isRead;
    return Semantics(
      button: true,
      label: alert.semanticLabel(now),
      excludeSemantics: true,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Container(
          decoration: unread
              ? BoxDecoration(
                  borderRadius: AppSpacing.radius3xl,
                  border: Border.all(color: context.colors.primary, width: 2),
                )
              : null,
          child: SafeCard(
            interactive: true,
            onTap: onTap,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (unread) ...[
                    _NewBadge(),
                    const SizedBox(height: AppSpacing.s2),
                  ],
                  Text(
                    alert.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: unread ? FontWeight.bold : FontWeight.w500,
                      color: unread
                          ? context.colors.secondary
                          : context.colors.textMutedForeground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    '${alert.source} · ${alert.timeLabel(now)}',
                    style: textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      color: context.colors.textMutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: AppSpacing.radiusFull,
      ),
      child: Text(
        AppStrings.notificationsBadgeNew.tr(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: context.colors.textPrimaryForeground,
        ),
      ),
    );
  }
}
