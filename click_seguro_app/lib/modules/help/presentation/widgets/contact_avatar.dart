import 'dart:io';

import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

class ContactAvatar extends StatelessWidget {
  const ContactAvatar({
    super.key,
    required this.name,
    required this.radius,
    this.photoPath,
    this.semanticLabel,
  });

  final String name;
  final double radius;
  final String? photoPath;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    final initials = _initials(name);
    return Semantics(
      label: semanticLabel ?? name,
      image: true,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: context.colors.primary.withValues(alpha: .12),
        child: ClipOval(
          child: path == null
              ? _initialsView(context, initials)
              : Image.file(
                  File(path),
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _initialsView(context, initials),
                ),
        ),
      ),
    );
  }

  Widget _initialsView(BuildContext context, String initials) => Center(
    child: Text(
      initials,
      style: TextStyle(
        color: context.colors.secondary,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.first.isEmpty) return '?';
    final first = String.fromCharCode(parts.first.runes.first);
    if (parts.length == 1 || parts.last.isEmpty) return first.toUpperCase();
    return '$first${String.fromCharCode(parts.last.runes.first)}'.toUpperCase();
  }
}
