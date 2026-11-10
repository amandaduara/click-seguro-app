import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Escala de texto do redesign 2.0 em Inter (R3 de specs/022-redesign-visual).
/// Corpo de 18 e nada abaixo de 15 (FR-003). Sem cor: ela vem do
/// [textTheme] ou de `context.colors`.
abstract final class AppTypography {
  static const String fontFamily = 'Inter';

  /// Título de tela.
  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.15,
  );

  /// Títulos fortes: conclusão, estados, enunciado.
  static const TextStyle title1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  /// Seções.
  static const TextStyle title2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.25,
  );

  /// Cartões.
  static const TextStyle title3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// Leitura longa (notícia, explicações).
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Padrão.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );

  /// Rótulos, links, chips e botões compactos.
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// Metadados: o menor tamanho do app.
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  /// Botões grandes.
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  /// Placar da conclusão do módulo.
  static const TextStyle score = TextStyle(
    fontFamily: fontFamily,
    fontSize: 72,
    fontWeight: FontWeight.w800,
    letterSpacing: -2,
    height: 1,
  );

  /// Os estilos no [TextTheme] do Material, com as cores da [palette].
  static TextTheme textTheme(AppPalette palette) => TextTheme(
    displayLarge: display.copyWith(color: palette.textForeground),
    displayMedium: title1.copyWith(color: palette.textForeground),
    titleLarge: title2.copyWith(color: palette.textForeground),
    titleMedium: title3.copyWith(color: palette.textForeground),
    bodyLarge: bodyLarge.copyWith(color: palette.textBody),
    bodyMedium: body.copyWith(color: palette.textBody),
    bodySmall: caption.copyWith(color: palette.textMutedForeground),
    labelLarge: label.copyWith(color: palette.textForeground),
    labelMedium: caption.copyWith(color: palette.textForeground),
  );
}
