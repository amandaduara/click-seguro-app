import 'package:flutter/material.dart';

abstract class AppColors {
  AppColors._();

  // Cores Principais
  static const Color primary = Color(0xFFFE3152);
  static const Color secondary = Color(0xFF182A4E);
  
  // Cores de Fundo e Estrutura
  static const Color background = Color(0xFFFFFDFB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color primaryGlow = Color(0xFFFF6A7A);
  static const Color border = Color(0xFFE6E6EA);
  static const Color destructive = Color(0xFFE5484D);
  static const Color input = Color(0xFFEDEDF1);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  // Gradiente
  static const gradient = LinearGradient(
    colors: [primary, primaryGlow],
  );

  // Cores de Texto (Foregrounds)
  static const Color textForeground = Color(0xFF121932);
  static const Color textMutedForeground = Color(0xFF596475);
  static const Color textPrimaryForeground = Color(0xFFFFFFFF);

  // Sombras
  static const shadowSm = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static const shadowMd = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const shadowPrimary = [
    BoxShadow(color: Color(0x66FE3152), blurRadius: 24, offset: Offset(0, 10)),
  ];
}