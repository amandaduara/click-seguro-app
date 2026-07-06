import 'package:flutter/material.dart';

abstract class AppColors {
  AppColors._();

  // Cores Principais
  static const Color primary = Color(0xFFFE3152);
  static const Color secondary = Color(0xFF182A4E);
  
  // Cores de Fundo e Estrutura
  static const Color background = Color(0xFFFFFDFB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDADEE5);

  // Cores de Texto (Foregrounds)
  static const Color textForeground = Color(0xFF121932);
  static const Color textMutedForeground = Color(0xFF596475);
  static const Color textPrimaryForeground = Color(0xFFFFFFFF);
}