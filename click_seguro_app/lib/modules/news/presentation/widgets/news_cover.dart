import 'package:click_seguro_app/core/illustrations/illustration_theme.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/widgets/safe_badge.dart';
import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
import 'package:click_seguro_app/core/widgets/safe_network_image.dart';
import 'package:click_seguro_app/core/widgets/safe_skeleton.dart';
import 'package:flutter/material.dart';

/// Capa de notícia do redesign 2.0 (FR-015): a imagem da notícia, ou, sem
/// imagem ou se ela falhar, uma ilustração do tema sobre o fundo pastel.
/// O selo da categoria fica sobre a capa, no canto de cima.
class NewsCover extends StatelessWidget {
  const NewsCover({
    super.key,
    required this.imageUrl,
    required this.themeText,
    required this.height,
    this.labels = const [],
    this.radius = 20,
    this.trailing,
  });

  final String? imageUrl;

  /// Texto do qual sai o tema da ilustração (categoria, senão título).
  final String themeText;
  final double height;

  /// Selos das categorias sobre a capa (RF-012).
  final List<String> labels;
  final double radius;

  /// Sinais no canto direito (lida, salva).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final IllustrationTheme theme = IllustrationTheme.fromText(themeText);
    // No esqueleto (carregando), só o bloco cinza, sem a ilustração
    // (validação da usuária, specs/023).
    final Widget illustration = SafeSkeleton.leaf(
      ColoredBox(
        color: theme.pastel(colors),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SafeIllustration(theme.illustration),
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Decodifica no tamanho mostrado e esmaece ao chegar (specs/022
            // R11); a ilustração cobre a espera e a falha.
            SafeNetworkImage(
              url: imageUrl,
              height: height,
              placeholder: illustration,
            ),
            if (labels.isNotEmpty)
              Positioned(
                left: 10,
                top: 10,
                right: trailing == null ? 10 : 56,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final String label in labels)
                      SafeBadge(
                        tone: SafeBadgeTone.onImage,
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            if (trailing != null)
              Positioned(right: 10, top: 10, child: trailing!),
          ],
        ),
      ),
    );
  }
}
