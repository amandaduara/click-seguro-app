import 'package:flutter/material.dart';

abstract class AppSpacing {
  AppSpacing._();

  // Escala Tailwind (1 unidade = 4px)
  static const double s1 = 4.0;   
  static const double s2 = 8.0;   
  static const double s3 = 12.0;  
  static const double s4 = 16.0;  
  static const double s5 = 20.0;  
  static const double s6 = 24.0;  

  // Border Radius
  static final BorderRadius radius2xl = BorderRadius.circular(20.0);
  static final BorderRadius radius3xl = BorderRadius.circular(24.0);
  static const BorderRadius radiusFull = BorderRadius.all(Radius.circular(999.0));
}