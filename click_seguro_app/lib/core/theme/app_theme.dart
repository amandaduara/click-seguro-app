import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

abstract class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Montserrat',
      scaffoldBackgroundColor: AppColors.background,

      // Customização das Cores ---
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.card,
        error: AppColors.primary,
      ),

      // Customização dos Textos ---
      textTheme: const TextTheme(
        displayLarge: TextStyle( // text-3xl (30px / bold) - Título de tela grande
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: AppColors.textForeground,
          letterSpacing: -0.6,
        ),

        titleLarge: TextStyle( // text-2xl (24px / bold) - Títulos de header
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textForeground,
          letterSpacing: -0.48,
        ),
        
        titleMedium: TextStyle( // text-lg (18px / bold) - Títulos de seção / cards
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textForeground,
        ),
        
        bodyLarge: TextStyle( // text-base (16px / regular) - Corpo destacado / Inputs
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textForeground,
        ),
        
        bodyMedium: TextStyle( // text-sm (14px / regular) - Corpo padrão / botões
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textMutedForeground,
        ),
        
        bodySmall: TextStyle( // text-xs (12px / regular) - Legendas / metadados
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textMutedForeground,
        ),
      ),

      // Customização dos Cards ---
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.radius2xl,
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // Customização dos Inputs ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.radius2xl,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radius2xl,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
