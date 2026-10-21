import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Ícone do módulo vindo do serviço; sem ícone, carregando ou com erro,
/// mostra o ícone padrão (FR-012, R9). Decorativo para o leitor de tela.
class ModuleIcon extends StatelessWidget {
  const ModuleIcon({super.key, this.url});

  static const double size = 48;

  final String? url;

  @override
  Widget build(BuildContext context) {
    final String? src = url;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: src == null
            ? const _DefaultIcon()
            : Image.network(
                src,
                width: size,
                height: size,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : const _DefaultIcon(),
                errorBuilder: (context, _, _) => const _DefaultIcon(),
              ),
      ),
    );
  }
}

class _DefaultIcon extends StatelessWidget {
  const _DefaultIcon();

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(LucideIcons.graduationCap, size: 28, color: colors.primary),
    );
  }
}
