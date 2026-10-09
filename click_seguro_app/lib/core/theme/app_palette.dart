import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Cores do tema em uso: [light] (design system, [AppColors]) ou
/// [highContrast] (RF-039, WCAG AAA). Os widgets leem por `context.colors`,
/// para que a troca de tema chegue a todas as telas.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.card,
    required this.primaryGlow,
    required this.border,
    required this.destructive,
    required this.input,
    required this.inputBorder,
    required this.success,
    required this.warning,
    required this.textForeground,
    required this.textMutedForeground,
    required this.textPrimaryForeground,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowPrimary,
  });

  static const AppPalette light = AppPalette(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    background: AppColors.background,
    card: AppColors.card,
    primaryGlow: AppColors.primaryGlow,
    border: AppColors.border,
    destructive: AppColors.destructive,
    input: AppColors.input,
    inputBorder: AppColors.input,
    success: AppColors.success,
    warning: AppColors.warning,
    textForeground: AppColors.textForeground,
    textMutedForeground: AppColors.textMutedForeground,
    textPrimaryForeground: AppColors.textPrimaryForeground,
    shadowSm: AppColors.shadowSm,
    shadowMd: AppColors.shadowMd,
    shadowPrimary: AppColors.shadowPrimary,
  );

  /// Razões medidas em `specs/009-acessibilidade-global/research.md` (R2).
  /// O gradiente vira cor sólida e as sombras dão lugar à borda preta.
  static const AppPalette highContrast = AppPalette(
    primary: Color(0xFF9E0019),
    secondary: Color(0xFF0B1A3A),
    background: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    primaryGlow: Color(0xFF9E0019),
    border: Color(0xFF000000),
    destructive: Color(0xFF9E0019),
    input: Color(0xFFF2F2F2),
    inputBorder: Color(0xFF000000),
    success: Color(0xFF005A3C),
    warning: Color(0xFF6E4200),
    textForeground: Color(0xFF000000),
    textMutedForeground: Color(0xFF333333),
    textPrimaryForeground: Color(0xFFFFFFFF),
    shadowSm: [],
    shadowMd: [],
    shadowPrimary: [],
  );

  final Color primary;
  final Color secondary;
  final Color background;
  final Color card;
  final Color primaryGlow;
  final Color border;
  final Color destructive;
  final Color input;

  /// Contorno dos campos de texto sem foco: no alto contraste precisa de
  /// 3:1, e o [input] é cor de preenchimento.
  final Color inputBorder;
  final Color success;
  final Color warning;
  final Color textForeground;
  final Color textMutedForeground;
  final Color textPrimaryForeground;
  final List<BoxShadow> shadowSm;
  final List<BoxShadow> shadowMd;
  final List<BoxShadow> shadowPrimary;

  LinearGradient get gradient => LinearGradient(colors: [primary, primaryGlow]);

  @override
  AppPalette copyWith({
    Color? primary,
    Color? secondary,
    Color? background,
    Color? card,
    Color? primaryGlow,
    Color? border,
    Color? destructive,
    Color? input,
    Color? inputBorder,
    Color? success,
    Color? warning,
    Color? textForeground,
    Color? textMutedForeground,
    Color? textPrimaryForeground,
    List<BoxShadow>? shadowSm,
    List<BoxShadow>? shadowMd,
    List<BoxShadow>? shadowPrimary,
  }) => AppPalette(
    primary: primary ?? this.primary,
    secondary: secondary ?? this.secondary,
    background: background ?? this.background,
    card: card ?? this.card,
    primaryGlow: primaryGlow ?? this.primaryGlow,
    border: border ?? this.border,
    destructive: destructive ?? this.destructive,
    input: input ?? this.input,
    inputBorder: inputBorder ?? this.inputBorder,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    textForeground: textForeground ?? this.textForeground,
    textMutedForeground: textMutedForeground ?? this.textMutedForeground,
    textPrimaryForeground: textPrimaryForeground ?? this.textPrimaryForeground,
    shadowSm: shadowSm ?? this.shadowSm,
    shadowMd: shadowMd ?? this.shadowMd,
    shadowPrimary: shadowPrimary ?? this.shadowPrimary,
  );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    List<BoxShadow> s(List<BoxShadow> a, List<BoxShadow> b) =>
        BoxShadow.lerpList(a, b, t) ?? const [];
    return AppPalette(
      primary: c(primary, other.primary),
      secondary: c(secondary, other.secondary),
      background: c(background, other.background),
      card: c(card, other.card),
      primaryGlow: c(primaryGlow, other.primaryGlow),
      border: c(border, other.border),
      destructive: c(destructive, other.destructive),
      input: c(input, other.input),
      inputBorder: c(inputBorder, other.inputBorder),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      textForeground: c(textForeground, other.textForeground),
      textMutedForeground: c(textMutedForeground, other.textMutedForeground),
      textPrimaryForeground: c(
        textPrimaryForeground,
        other.textPrimaryForeground,
      ),
      shadowSm: s(shadowSm, other.shadowSm),
      shadowMd: s(shadowMd, other.shadowMd),
      shadowPrimary: s(shadowPrimary, other.shadowPrimary),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppPalette &&
      other.primary == primary &&
      other.secondary == secondary &&
      other.background == background &&
      other.card == card &&
      other.primaryGlow == primaryGlow &&
      other.border == border &&
      other.destructive == destructive &&
      other.input == input &&
      other.inputBorder == inputBorder &&
      other.success == success &&
      other.warning == warning &&
      other.textForeground == textForeground &&
      other.textMutedForeground == textMutedForeground &&
      other.textPrimaryForeground == textPrimaryForeground &&
      listEquals(other.shadowSm, shadowSm) &&
      listEquals(other.shadowMd, shadowMd) &&
      listEquals(other.shadowPrimary, shadowPrimary);

  @override
  int get hashCode => Object.hash(
    primary,
    secondary,
    background,
    card,
    primaryGlow,
    border,
    destructive,
    input,
    inputBorder,
    success,
    warning,
    textForeground,
    textMutedForeground,
    textPrimaryForeground,
    Object.hashAll(shadowSm),
    Object.hashAll(shadowMd),
    Object.hashAll(shadowPrimary),
  );
}

extension AppPaletteContext on BuildContext {
  /// Paleta do tema em uso; sem ela (ex.: testes com `MaterialApp` cru), a
  /// light.
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
