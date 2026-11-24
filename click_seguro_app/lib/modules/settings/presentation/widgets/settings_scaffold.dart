import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/safe_page_header.dart';
import 'package:flutter/material.dart';

/// Quadro das telas das Configurações no redesign 2.0: o cabeçalho padrão
/// ([SafePageHeader]: voltar redondo e, na mesma linha, o título grande) e o
/// conteúdo rolando abaixo. [bottom] (ex.: o botão principal) fica fixo no
/// fim da tela, acima da área segura e do teclado.
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
    return SafePageScaffold(
      header: SafePageHeader(title: title, fallbackLocation: fallbackLocation),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s2,
          AppSpacing.s5,
          AppSpacing.s8,
        ),
        children: children,
      ),
      bottom: bottom,
    );
  }
}
