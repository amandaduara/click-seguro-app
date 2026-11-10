import 'package:flutter/material.dart';

abstract class AppSpacing {
  AppSpacing._();

  // Escala de 4 em 4
  static const double s1 = 4.0;
  static const double s2 = 8.0;
  static const double s3 = 12.0;
  static const double s4 = 16.0;
  static const double s5 = 20.0;
  static const double s6 = 24.0;
  static const double s7 = 32.0;
  static const double s8 = 48.0;

  // Cantos (R4 de specs/023-redesign-visual)
  /// Peças internas pequenas.
  static final BorderRadius radiusSm = BorderRadius.circular(12.0);

  /// Botões e campos.
  static final BorderRadius radiusMd = BorderRadius.circular(16.0);

  /// Cartões.
  static final BorderRadius radiusLg = BorderRadius.circular(20.0);

  /// Destaques e capas grandes.
  static final BorderRadius radiusXl = BorderRadius.circular(24.0);

  /// Folhas inferiores.
  static final BorderRadius radius2xl = BorderRadius.circular(32.0);

  static const BorderRadius radiusFull = BorderRadius.all(
    Radius.circular(999.0),
  );
}
