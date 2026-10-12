import 'dart:io';

import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Foto redonda da pessoa: a cópia local (envio em andamento), a do serviço
/// ou as iniciais. Foto que não carrega também vira iniciais.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.initials,
    this.imageUrl,
    this.localPath,
    this.size = 96,
  });

  final String initials;
  final String? imageUrl;
  final String? localPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = _Initials(initials: initials, size: size);
    final String? local = localPath;
    final String? url = imageUrl;
    final Widget content = local != null
        ? Image.file(
            File(local),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          )
        : url != null
        ? Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          )
        : fallback;
    return ExcludeSemantics(
      child: ClipOval(
        child: SizedBox.square(dimension: size, child: content),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: context.colors.input),
      child: Center(
        child: Text(
          initials,
          // Tamanho fixo pela foto: a fonte do sistema não cabe no círculo.
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w800,
            color: context.colors.secondary,
          ),
        ),
      ),
    );
  }
}
