import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/illustrations/illustration_theme.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
import 'package:click_seguro_app/core/widgets/safe_network_image.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';
import 'package:click_seguro_app/modules/notifications/presentation/extensions/alert_presentation_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Um alerta na lista, no estilo dos cartões do Início (validação da
/// usuária, specs/023): capa da notícia à esquerda e, ao lado, "Novo" escrito
/// (além da cor) quando não lido, título e "fonte · hora/data". Cartão
/// inteiro tocável, bem acima de 48 dp.
class AlertTile extends StatelessWidget {
  const AlertTile({
    super.key,
    required this.alert,
    required this.now,
    required this.onTap,
  });

  /// Lado da capa.
  static const double _thumb = 88;

  final AlertEntity alert;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final bool unread = !alert.isRead;
    return Semantics(
      button: true,
      label: alert.semanticLabel(now),
      excludeSemantics: true,
      onTap: onTap,
      child: Container(
        // Não lido: contorno coral em volta do cartão.
        decoration: unread
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.primary, width: 2),
              )
            : null,
        child: SafeCard(
          interactive: true,
          onTap: onTap,
          padded: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumb(alert: alert, size: _thumb),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (unread) ...[
                        _NewBadge(),
                        const SizedBox(height: AppSpacing.s2),
                      ],
                      Text(
                        alert.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(
                          fontWeight: unread
                              ? FontWeight.w700
                              : FontWeight.w500,
                          height: 1.3,
                          color: unread
                              ? colors.secondary
                              : colors.textMutedForeground,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s1),
                      Text(
                        '${alert.source} · ${alert.timeLabel(now)}',
                        style: AppTypography.caption.copyWith(
                          color: colors.textMutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A capa da notícia; sem ela (ou enquanto carrega), a ilustração do tema
/// sobre o fundo pastel, como nos cartões do Início.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.alert, required this.size});

  final AlertEntity alert;
  final double size;

  @override
  Widget build(BuildContext context) {
    final IllustrationTheme theme = IllustrationTheme.fromText(alert.title);
    return ClipRRect(
      borderRadius: AppSpacing.radiusMd,
      child: SizedBox.square(
        dimension: size,
        child: SafeNetworkImage(
          url: alert.imageUrl,
          width: size,
          height: size,
          placeholder: ColoredBox(
            color: theme.pastel(context.colors),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s2),
              child: SafeIllustration(theme.illustration),
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
          fontSize: AppTypography.caption.fontSize,
          fontWeight: FontWeight.bold,
          color: context.colors.textPrimaryForeground,
        ),
      ),
    );
  }
}
