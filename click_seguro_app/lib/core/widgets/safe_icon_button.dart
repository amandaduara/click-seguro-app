import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Botão redondo só com ícone (redesign 2.0): creme, ou branco com a sombra
/// única quando fica sobre uma imagem. O rótulo é obrigatório, porque o
/// ícone sozinho não diz nada ao leitor de tela (FR-005, RNF-004).
class SafeIconButton extends StatelessWidget {
  const SafeIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.onImage = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool onImage;

  /// Alvo de toque mínimo (RNF-003).
  static const double _size = 48;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final bool highContrast = colors.shadow.isEmpty;
    return Semantics(
      button: true,
      label: semanticLabel,
      enabled: onPressed != null,
      // Sem isto o excludeSemantics tira a ação do InkWell e o leitor de
      // tela não consegue tocar no botão.
      onTap: onPressed,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: _size,
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: BoxDecoration(
              color: onImage ? colors.card : colors.surface,
              shape: BoxShape.circle,
              boxShadow: onImage ? colors.shadow : null,
              border: highContrast ? Border.all(color: colors.border) : null,
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Icon(icon, size: 24, color: colors.textForeground),
            ),
          ),
        ),
      ),
    );
  }
}
