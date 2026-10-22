import 'dart:io';

import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/utils/person_initials.dart';
import 'package:flutter/material.dart';

/// Foto circular com iniciais de fallback para pessoas do perfil e contatos.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    this.name,
    this.initials,
    this.photoPath,
    this.imageUrl,
    this.size = 96,
    this.semanticLabel,
  });

  final String? name;
  final String? initials;
  final String? photoPath;
  final String? imageUrl;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final label = semanticLabel ?? name;
    final computedInitials = personInitials(name ?? '');
    final letters =
        initials ?? (computedInitials.isEmpty ? '?' : computedInitials);
    final fallback = DecoratedBox(
      decoration: BoxDecoration(color: context.colors.input),
      child: Center(
        child: Text(
          letters,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontSize: size * .36,
            fontWeight: FontWeight.w800,
            color: context.colors.secondary,
          ),
        ),
      ),
    );
    final path = photoPath;
    final url = imageUrl;
    final Widget image = path != null
        ? Image.file(
            File(path),
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
    return Semantics(
      label: label,
      image: true,
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: .12),
            ),
            child: image,
          ),
        ),
      ),
    );
  }
}
