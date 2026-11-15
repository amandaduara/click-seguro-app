import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/widgets/person_avatar.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Foto editável: o círculo com a foto (ou as iniciais) e um selo coral com
/// a câmera no canto. Tocar abre a escolha da foto (quem usa decide o que
/// fazer). Com [busy], mostra o carregamento por cima e não aceita toque.
///
/// Visual da edição de perfil, também no contato de confiança (validação da
/// usuária, specs/024).
class EditableAvatar extends StatelessWidget {
  const EditableAvatar({
    super.key,
    required this.semanticLabel,
    this.name,
    this.initials,
    this.imageUrl,
    this.photoPath,
    this.size = 96,
    this.busy = false,
    this.onTap,
  });

  /// O que o leitor de tela diz ("Trocar foto").
  final String semanticLabel;
  final String? name;
  final String? initials;
  final String? imageUrl;
  final String? photoPath;
  final double size;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final VoidCallback? tap = busy ? null : onTap;
    return Semantics(
      container: true,
      button: true,
      enabled: tap != null,
      label: semanticLabel,
      onTap: tap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: tap,
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            children: [
              PersonAvatar(
                name: name,
                initials: initials,
                imageUrl: imageUrl,
                photoPath: photoPath,
                size: size,
              ),
              if (busy)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.secondary.withValues(alpha: 0.45),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: colors.textPrimaryForeground,
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.card, width: 3),
                  ),
                  child: Icon(
                    LucideIcons.camera,
                    size: 14,
                    color: colors.textPrimaryForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
