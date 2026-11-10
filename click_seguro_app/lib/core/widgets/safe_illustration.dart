import 'package:click_seguro_app/core/illustrations/app_illustration.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Ilustração decorativa do redesign (FR-017), fora da árvore de semântica.
/// No alto contraste, as cores do desenho viram as da paleta AAA (FR-002,
/// R5 de specs/023-redesign-visual).
class SafeIllustration extends StatelessWidget {
  const SafeIllustration(this.illustration, {super.key, this.height});

  final AppIllustration illustration;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final bool highContrast = context.colors.shadow.isEmpty;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: SvgPicture(
          SvgAssetLoader(
            illustration.asset,
            colorMapper: highContrast ? const _HighContrastColorMapper() : null,
          ),
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}

/// Troca cada cor da paleta das ilustrações pela equivalente do alto
/// contraste: pastéis e claros → branco, escuros → preto, coral, verde e
/// dourado → os tons AAA da [AppPalette.highContrast].
class _HighContrastColorMapper extends ColorMapper {
  const _HighContrastColorMapper();

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _black = Color(0xFF000000);

  static final Map<int, Color> _map = {
    0xFFE31C3D: AppPalette.highContrast.primary, // coral
    0xFFFFB3BF: AppPalette.highContrast.primary, // rosa do confete
    0xFF0F7B4F: AppPalette.highContrast.success, // verde
    0xFF9FD5B5: AppPalette.highContrast.success, // menta
    0xFFF5B731: AppPalette.highContrast.warning, // dourado
    0xFF1B2440: _black, // tinta
    0xFF3A4566: _black,
  };

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    final Color opaque = color.withValues(alpha: 1);
    final Color? mapped = _map[opaque.toARGB32()];
    if (mapped != null) return mapped.withValues(alpha: color.a);
    // O que sobra é claro (branco, cinza, pastéis): vira branco.
    return _white.withValues(alpha: color.a);
  }
}
