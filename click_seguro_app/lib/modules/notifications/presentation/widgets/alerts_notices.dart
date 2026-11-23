import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_button.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:click_seguro_app/core/widgets/safe_offline_banner.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Faixas fixas no alto da tela de alertas, no lugar de avisos que somem
/// sozinhos (R12 de specs/011-alertas-locais).
class AlertsNotices extends StatelessWidget {
  const AlertsNotices({
    super.key,
    required this.showOffline,
    required this.showsSavedContent,
    required this.showDisabled,
    required this.onOpenSettings,
  });

  /// Onde se liga "Receber alertas": a chave das Configurações
  /// (specs/013-configuracoes), por caminho, sem importar `settings`.
  static const String settingsRoute = '/settings';

  /// A última conferência falhou por falta de conexão.
  final bool showOffline;

  /// Há alertas guardados na lista; sem eles, a faixa diz só que está sem
  /// internet (specs/027 FR-011).
  final bool showsSavedContent;

  /// "Receber alertas" está desligado na conta.
  final bool showDisabled;

  /// Abre as Configurações; a tela confere de novo na volta.
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    if (!showOffline && !showDisabled) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showOffline)
          SafeOfflineBanner(showsSavedContent: showsSavedContent),
        if (showDisabled) _DisabledNotice(onOpenSettings: onOpenSettings),
      ],
    );
  }
}

/// Aviso de alertas desligados, com o caminho para ligar de volta: um
/// cartão do app (redesign 2.0) com o sino cortado num círculo suave na cor
/// de atenção e o botão principal.
class _DisabledNotice extends StatelessWidget {
  const _DisabledNotice({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s3,
        AppSpacing.s5,
        AppSpacing.s2,
      ),
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Container(
          decoration: SafeCard.decoration(colors),
          padding: const EdgeInsets.all(AppSpacing.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const _AttentionIconCircle(icon: LucideIcons.bellOff),
                  const SizedBox(width: AppSpacing.s4),
                  Expanded(
                    child: Text(
                      AppStrings.notificationsDisabledNotice.tr(),
                      style: AppTypography.body.copyWith(
                        color: colors.textForeground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              SafeButton(
                label: AppStrings.notificationsDisabledAction.tr(),
                onPressed: onOpenSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ícone num círculo suave na cor de atenção (como os das Configurações);
/// decorativo: o texto ao lado já diz tudo.
class _AttentionIconCircle extends StatelessWidget {
  const _AttentionIconCircle({required this.icon});

  final IconData icon;

  static const double size = 44;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final bool highContrast = colors.shadow.isEmpty;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.warningSoft,
          shape: BoxShape.circle,
          border: highContrast ? Border.all(color: colors.border) : null,
        ),
        child: Icon(icon, size: 22, color: colors.warning),
      ),
    );
  }
}
