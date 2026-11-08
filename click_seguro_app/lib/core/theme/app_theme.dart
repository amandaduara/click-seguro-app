import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_page_transitions.dart';
import 'app_palette.dart';
import 'app_spacing.dart';

abstract class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(AppPalette.light);

  /// Alto contraste (RF-039): mesmas medidas, cores de [AppPalette.highContrast].
  static ThemeData get highContrastTheme => _build(AppPalette.highContrast);

  static ThemeData _build(AppPalette palette) {
    return ThemeData(
      useMaterial3: true,
      extensions: [palette],
      fontFamily: 'Montserrat',
      scaffoldBackgroundColor: palette.background,

      // Telas empilhadas: volta preditiva no Android, deslize no iOS; corte
      // seco com o movimento reduzido (specs/022 R4).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: MotionAwareTransitionsBuilder(
            PredictiveBackPageTransitionsBuilder(),
          ),
          TargetPlatform.iOS: MotionAwareTransitionsBuilder(
            CupertinoPageTransitionsBuilder(),
          ),
          TargetPlatform.macOS: MotionAwareTransitionsBuilder(
            CupertinoPageTransitionsBuilder(),
          ),
          TargetPlatform.windows: MotionAwareTransitionsBuilder(
            ZoomPageTransitionsBuilder(),
          ),
          TargetPlatform.linux: MotionAwareTransitionsBuilder(
            ZoomPageTransitionsBuilder(),
          ),
          TargetPlatform.fuchsia: MotionAwareTransitionsBuilder(
            ZoomPageTransitionsBuilder(),
          ),
        },
      ),

      // Customização das Cores ---
      colorScheme: ColorScheme.light(
        primary: palette.primary,
        secondary: palette.secondary,
        surface: palette.card,
        error: palette.primary,
      ),

      // Customização dos Textos ---
      textTheme: TextTheme(
        displayLarge: TextStyle(
          // text-3xl (30px / bold) - Título de tela grande
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: palette.textForeground,
          letterSpacing: -0.6,
        ),

        titleLarge: TextStyle(
          // text-2xl (24px / bold) - Títulos de header
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: palette.textForeground,
          letterSpacing: -0.48,
        ),

        titleMedium: TextStyle(
          // text-lg (18px / bold) - Títulos de seção / cards
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: palette.textForeground,
        ),

        bodyLarge: TextStyle(
          // text-base (16px / regular) - Corpo destacado / Inputs
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: palette.textForeground,
        ),

        bodyMedium: TextStyle(
          // text-sm (14px / regular) - Corpo padrão / botões
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: palette.textMutedForeground,
        ),

        bodySmall: TextStyle(
          // text-xs (12px / regular) - Legendas / metadados
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: palette.textMutedForeground,
        ),
      ),

      // Customização dos Cards ---
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.radius2xl,
          side: BorderSide(color: palette.border, width: 1),
        ),
      ),

      // Customização dos Inputs ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.radius2xl,
          borderSide: BorderSide(color: palette.border),
        ),
      ),
    );
  }
}
