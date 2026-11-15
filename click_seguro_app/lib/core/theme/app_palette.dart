import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Cores do tema em uso: [light] (redesign 2.0, [AppColors]) ou
/// [highContrast] (RF-039, WCAG AAA). Os widgets leem por `context.colors`,
/// para que a troca de tema chegue a todas as telas.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.primaryPressed,
    required this.primarySoft,
    required this.primaryGlow,
    required this.secondary,
    required this.background,
    required this.card,
    required this.surface,
    required this.surfaceStrong,
    required this.border,
    required this.destructive,
    required this.input,
    required this.inputBorder,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.info,
    required this.infoSoft,
    required this.textForeground,
    required this.textBody,
    required this.textMutedForeground,
    required this.textPrimaryForeground,
    required this.pastelPeach,
    required this.pastelSage,
    required this.pastelSky,
    required this.pastelButter,
    required this.pastelLilac,
    required this.shadow,
  });

  static const AppPalette light = AppPalette(
    primary: AppColors.primary,
    primaryPressed: AppColors.primaryPressed,
    primarySoft: AppColors.primarySoft,
    primaryGlow: AppColors.primaryGlow,
    secondary: AppColors.secondary,
    background: AppColors.background,
    card: AppColors.card,
    surface: AppColors.surface,
    surfaceStrong: AppColors.surfaceStrong,
    border: AppColors.border,
    destructive: AppColors.destructive,
    input: AppColors.input,
    inputBorder: AppColors.inputBorder,
    success: AppColors.success,
    successSoft: AppColors.successSoft,
    warning: AppColors.warning,
    warningSoft: AppColors.warningSoft,
    info: AppColors.info,
    infoSoft: AppColors.infoSoft,
    textForeground: AppColors.textForeground,
    textBody: AppColors.textBody,
    textMutedForeground: AppColors.textMutedForeground,
    textPrimaryForeground: AppColors.textPrimaryForeground,
    pastelPeach: AppColors.pastelPeach,
    pastelSage: AppColors.pastelSage,
    pastelSky: AppColors.pastelSky,
    pastelButter: AppColors.pastelButter,
    pastelLilac: AppColors.pastelLilac,
    shadow: AppColors.shadow,
  );

  /// Razões medidas em `specs/009-acessibilidade-global/research.md` (R2) e
  /// estendidas no redesign: os "suaves" e pastéis viram branco e as sombras
  /// dão lugar à borda preta.
  static const AppPalette highContrast = AppPalette(
    primary: Color(0xFF9E0019),
    primaryPressed: Color(0xFF7A0013),
    primarySoft: _white,
    primaryGlow: Color(0xFF9E0019),
    secondary: Color(0xFF0B1A3A),
    background: _white,
    card: _white,
    surface: _white,
    surfaceStrong: Color(0xFFF2F2F2),
    border: Color(0xFF000000),
    destructive: Color(0xFF9E0019),
    input: Color(0xFFF2F2F2),
    inputBorder: Color(0xFF000000),
    success: Color(0xFF005A3C),
    successSoft: _white,
    warning: Color(0xFF6E4200),
    warningSoft: _white,
    info: Color(0xFF0B3A9E),
    infoSoft: _white,
    textForeground: Color(0xFF000000),
    textBody: Color(0xFF000000),
    textMutedForeground: Color(0xFF333333),
    textPrimaryForeground: _white,
    pastelPeach: _white,
    pastelSage: _white,
    pastelSky: _white,
    pastelButter: _white,
    pastelLilac: _white,
    shadow: [],
  );

  static const Color _white = Color(0xFFFFFFFF);

  final Color primary;

  /// Botão primário pressionado e texto coral sobre [primarySoft].
  final Color primaryPressed;

  /// Fundo da aba atual, dos selos de alerta e da seleção.
  final Color primarySoft;

  /// Coral mais claro da onda de trás da splash (specs/023-splash-animada).
  final Color primaryGlow;
  final Color secondary;
  final Color background;
  final Color card;

  /// Creme dos cartões planos, da busca e dos chips.
  final Color surface;

  /// Creme mais forte: botão secundário e trilho das abas.
  final Color surfaceStrong;
  final Color border;
  final Color destructive;
  final Color input;

  /// Contorno dos campos de texto sem foco (3:1 sobre o fundo).
  final Color inputBorder;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color info;
  final Color infoSoft;
  final Color textForeground;

  /// Texto corrido (parágrafos).
  final Color textBody;
  final Color textMutedForeground;
  final Color textPrimaryForeground;
  final Color pastelPeach;
  final Color pastelSage;
  final Color pastelSky;
  final Color pastelButter;
  final Color pastelLilac;

  /// A sombra única; vazia no alto contraste.
  final List<BoxShadow> shadow;

  List<Color> get _colors => [
    primary,
    primaryPressed,
    primarySoft,
    primaryGlow,
    secondary,
    background,
    card,
    surface,
    surfaceStrong,
    border,
    destructive,
    input,
    inputBorder,
    success,
    successSoft,
    warning,
    warningSoft,
    info,
    infoSoft,
    textForeground,
    textBody,
    textMutedForeground,
    textPrimaryForeground,
    pastelPeach,
    pastelSage,
    pastelSky,
    pastelButter,
    pastelLilac,
  ];

  @override
  AppPalette copyWith({
    Color? primary,
    Color? primaryPressed,
    Color? primarySoft,
    Color? primaryGlow,
    Color? secondary,
    Color? background,
    Color? card,
    Color? surface,
    Color? surfaceStrong,
    Color? border,
    Color? destructive,
    Color? input,
    Color? inputBorder,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? info,
    Color? infoSoft,
    Color? textForeground,
    Color? textBody,
    Color? textMutedForeground,
    Color? textPrimaryForeground,
    Color? pastelPeach,
    Color? pastelSage,
    Color? pastelSky,
    Color? pastelButter,
    Color? pastelLilac,
    List<BoxShadow>? shadow,
  }) => AppPalette(
    primary: primary ?? this.primary,
    primaryPressed: primaryPressed ?? this.primaryPressed,
    primarySoft: primarySoft ?? this.primarySoft,
    primaryGlow: primaryGlow ?? this.primaryGlow,
    secondary: secondary ?? this.secondary,
    background: background ?? this.background,
    card: card ?? this.card,
    surface: surface ?? this.surface,
    surfaceStrong: surfaceStrong ?? this.surfaceStrong,
    border: border ?? this.border,
    destructive: destructive ?? this.destructive,
    input: input ?? this.input,
    inputBorder: inputBorder ?? this.inputBorder,
    success: success ?? this.success,
    successSoft: successSoft ?? this.successSoft,
    warning: warning ?? this.warning,
    warningSoft: warningSoft ?? this.warningSoft,
    info: info ?? this.info,
    infoSoft: infoSoft ?? this.infoSoft,
    textForeground: textForeground ?? this.textForeground,
    textBody: textBody ?? this.textBody,
    textMutedForeground: textMutedForeground ?? this.textMutedForeground,
    textPrimaryForeground: textPrimaryForeground ?? this.textPrimaryForeground,
    pastelPeach: pastelPeach ?? this.pastelPeach,
    pastelSage: pastelSage ?? this.pastelSage,
    pastelSky: pastelSky ?? this.pastelSky,
    pastelButter: pastelButter ?? this.pastelButter,
    pastelLilac: pastelLilac ?? this.pastelLilac,
    shadow: shadow ?? this.shadow,
  );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      primary: c(primary, other.primary),
      primaryPressed: c(primaryPressed, other.primaryPressed),
      primarySoft: c(primarySoft, other.primarySoft),
      primaryGlow: c(primaryGlow, other.primaryGlow),
      secondary: c(secondary, other.secondary),
      background: c(background, other.background),
      card: c(card, other.card),
      surface: c(surface, other.surface),
      surfaceStrong: c(surfaceStrong, other.surfaceStrong),
      border: c(border, other.border),
      destructive: c(destructive, other.destructive),
      input: c(input, other.input),
      inputBorder: c(inputBorder, other.inputBorder),
      success: c(success, other.success),
      successSoft: c(successSoft, other.successSoft),
      warning: c(warning, other.warning),
      warningSoft: c(warningSoft, other.warningSoft),
      info: c(info, other.info),
      infoSoft: c(infoSoft, other.infoSoft),
      textForeground: c(textForeground, other.textForeground),
      textBody: c(textBody, other.textBody),
      textMutedForeground: c(textMutedForeground, other.textMutedForeground),
      textPrimaryForeground: c(
        textPrimaryForeground,
        other.textPrimaryForeground,
      ),
      pastelPeach: c(pastelPeach, other.pastelPeach),
      pastelSage: c(pastelSage, other.pastelSage),
      pastelSky: c(pastelSky, other.pastelSky),
      pastelButter: c(pastelButter, other.pastelButter),
      pastelLilac: c(pastelLilac, other.pastelLilac),
      // Sombra não se mistura com "sem sombra": troca na metade.
      shadow: t < 0.5 ? shadow : other.shadow,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppPalette &&
      listEquals(other._colors, _colors) &&
      listEquals(other.shadow, shadow);

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(_colors), Object.hashAll(shadow));
}

extension AppPaletteContext on BuildContext {
  /// Paleta do tema em uso; sem ela (ex.: testes com `MaterialApp` cru), a
  /// light.
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
