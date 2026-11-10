import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app_motion.dart';
import 'app_palette.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(AppPalette.light);

  /// Alto contraste (RF-039): mesmas medidas, cores de [AppPalette.highContrast].
  static ThemeData get highContrastTheme => _build(AppPalette.highContrast);

  static ThemeData _build(AppPalette palette) {
    final OutlineInputBorder idle = OutlineInputBorder(
      borderRadius: AppSpacing.radiusMd,
      borderSide: BorderSide(color: palette.inputBorder, width: 1.5),
    );
    return ThemeData(
      useMaterial3: true,
      extensions: [palette],
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: palette.background,
      colorScheme: ColorScheme.light(
        primary: palette.primary,
        onPrimary: palette.textPrimaryForeground,
        secondary: palette.secondary,
        surface: palette.card,
        onSurface: palette.textForeground,
        error: palette.destructive,
      ),
      textTheme: AppTypography.textTheme(palette),
      iconTheme: IconThemeData(color: palette.textForeground, size: 24),
      // Ícone de voltar da Lucide em todo o app (FR-005).
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const Icon(LucideIcons.arrowLeft),
        closeButtonIconBuilder: (_) => const Icon(LucideIcons.x),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textForeground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.title3.copyWith(
          fontWeight: FontWeight.w700,
          color: palette.textForeground,
        ),
      ),
      dividerTheme: DividerThemeData(color: palette.border, thickness: 1),
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.radiusLg,
          side: palette.shadow.isEmpty
              ? BorderSide(color: palette.border)
              : BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: 18,
        ),
        hintStyle: AppTypography.body.copyWith(
          color: palette.textMutedForeground,
        ),
        border: idle,
        enabledBorder: idle,
        focusedBorder: idle.copyWith(
          borderSide: BorderSide(color: palette.textForeground, width: 2.5),
        ),
        errorBorder: idle.copyWith(
          borderSide: BorderSide(color: palette.destructive, width: 2),
        ),
        focusedErrorBorder: idle.copyWith(
          borderSide: BorderSide(color: palette.destructive, width: 2.5),
        ),
        errorStyle: AppTypography.caption.copyWith(color: palette.destructive),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.secondary,
        contentTextStyle: AppTypography.label.copyWith(
          fontSize: 17,
          color: palette.textPrimaryForeground,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusMd),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusXl),
        titleTextStyle: AppTypography.title2.copyWith(
          color: palette.textForeground,
        ),
        contentTextStyle: AppTypography.body.copyWith(color: palette.textBody),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.primary
              : palette.surfaceStrong,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.linux: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeSlidePageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Troca de tela do redesign: a nova aparece e desliza 24 px (FR-020); com
/// "reduzir animações", troca direto (FR-021).
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  static const double _offset = 24;

  @override
  Duration get transitionDuration => AppMotion.standard;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (context.reduceMotion) return child;
    final Animation<double> curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.enter,
      reverseCurve: AppMotion.exit,
    );
    return FadeTransition(
      opacity: curved,
      child: AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (context, child) => Transform.translate(
          offset: Offset(_offset * (1 - curved.value), 0),
          child: child,
        ),
      ),
    );
  }
}
