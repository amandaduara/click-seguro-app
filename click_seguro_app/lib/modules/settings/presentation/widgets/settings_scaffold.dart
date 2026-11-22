import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/safe_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Quadro das telas das Configurações no redesign 2.0: no topo, o botão
/// redondo de voltar e, na mesma linha, logo ao lado, o título grande (como
/// nas outras telas principais); o conteúdo rola abaixo. Com letra grande o
/// título quebra linha em vez de estourar. [bottom] (ex.: o botão principal)
/// fica fixo no fim da tela, acima da área segura e do teclado.
class SettingsScaffold extends StatelessWidget {
  const SettingsScaffold({
    super.key,
    required this.title,
    required this.children,
    this.fallbackLocation = '/settings',
    this.bottom,
  });

  final String title;
  final List<Widget> children;

  /// Para onde o voltar leva quando a tela foi aberta por link direto, sem
  /// nada atrás dela.
  final String fallbackLocation;

  /// Fixo embaixo, fora da rolagem.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s5,
                AppSpacing.s3,
                AppSpacing.s5,
                0,
              ),
              child: Row(
                children: [
                  SettingsBackButton(fallbackLocation: fallbackLocation),
                  const SizedBox(width: AppSpacing.s4),
                  Expanded(child: _PageTitle(title)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s5,
                  AppSpacing.s2,
                  AppSpacing.s5,
                  AppSpacing.s8,
                ),
                children: children,
              ),
            ),
            if (bottom case final Widget bottom)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s5,
                  AppSpacing.s3,
                  AppSpacing.s5,
                  AppSpacing.s4,
                ),
                child: bottom,
              ),
          ],
        ),
      ),
    );
  }
}

/// Título grande da tela, no estilo do "Perfil", ao lado do voltar.
class _PageTitle extends StatelessWidget {
  const _PageTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontSize: AppTypography.display.fontSize,
          fontWeight: FontWeight.w800,
          height: 1.2,
          color: context.colors.secondary,
        ),
      ),
    );
  }
}

/// Botão redondo de voltar. Usa o `maybePop`, para o aviso de descartar da
/// troca de senha (PopScope) continuar valendo.
class SettingsBackButton extends StatelessWidget {
  const SettingsBackButton({super.key, required this.fallbackLocation});

  static const Key buttonKey = ValueKey('settings-back');

  final String fallbackLocation;

  Future<void> _back(BuildContext context) async {
    final bool handled = await Navigator.of(context).maybePop();
    if (!handled && context.mounted) context.go(fallbackLocation);
  }

  @override
  Widget build(BuildContext context) {
    return SafeIconButton(
      key: buttonKey,
      icon: LucideIcons.chevronLeft,
      semanticLabel: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => _back(context),
    );
  }
}
