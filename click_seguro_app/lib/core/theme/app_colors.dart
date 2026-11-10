import 'package:flutter/material.dart';

/// Cores do tema normal do redesign 2.0 (specs/023-redesign-visual,
/// data-model). Os widgets leem por `context.colors` ([AppPalette]), para a
/// troca pelo alto contraste chegar a todas as telas.
abstract class AppColors {
  AppColors._();

  // Ação
  static const Color primary = Color(0xFFE31C3D);
  static const Color primaryPressed = Color(0xFFC2112F);
  static const Color primarySoft = Color(0xFFFFE8EB);

  // Texto
  static const Color secondary = Color(0xFF1B2440);
  static const Color textForeground = Color(0xFF1B2440);
  static const Color textBody = Color(0xFF3D4457);
  static const Color textMutedForeground = Color(0xFF5E6577);
  static const Color textPrimaryForeground = Color(0xFFFFFFFF);

  // Superfícies
  static const Color background = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F5F0);
  static const Color surfaceStrong = Color(0xFFEFEBE3);
  static const Color border = Color(0xFFE4E1DA);
  static const Color input = Color(0xFFF7F5F0);

  /// Contorno dos campos: 3:1 sobre o fundo (WCAG 1.4.11).
  static const Color inputBorder = Color(0xFF8A8F9C);

  // Estados
  static const Color success = Color(0xFF0F7B4F);
  static const Color successSoft = Color(0xFFDFF3E8);
  static const Color warning = Color(0xFF8F5600);
  static const Color warningSoft = Color(0xFFFDF0D5);
  static const Color info = Color(0xFF2554C7);
  static const Color infoSoft = Color(0xFFE4ECFB);
  static const Color destructive = Color(0xFFC4122F);

  // Fundos das ilustrações
  static const Color pastelPeach = Color(0xFFFFD9CE);
  static const Color pastelSage = Color(0xFFD3E8DA);
  static const Color pastelSky = Color(0xFFD8E6F7);
  static const Color pastelButter = Color(0xFFFCEBB6);
  static const Color pastelLilac = Color(0xFFE6DFF6);

  /// A sombra única do redesign (R4): cartões e botões sobre imagem.
  static const List<BoxShadow> shadow = [
    BoxShadow(color: Color(0x05000000), spreadRadius: 1),
    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 4)),
  ];
}
