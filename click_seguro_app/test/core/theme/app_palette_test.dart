import 'package:click_seguro_app/core/theme/app_colors.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Razão de contraste WCAG 2.1 entre duas cores opacas.
double contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double light = la > lb ? la : lb;
  final double dark = la > lb ? lb : la;
  return (light + 0.05) / (dark + 0.05);
}

void main() {
  group('AppPalette.light', () {
    test('é o design system de sempre (AppColors)', () {
      const palette = AppPalette.light;

      expect(palette.primary, AppColors.primary);
      expect(palette.secondary, AppColors.secondary);
      expect(palette.background, AppColors.background);
      expect(palette.card, AppColors.card);
      expect(palette.primaryGlow, AppColors.primaryGlow);
      expect(palette.border, AppColors.border);
      expect(palette.destructive, AppColors.destructive);
      expect(palette.input, AppColors.input);
      expect(palette.success, AppColors.success);
      expect(palette.warning, AppColors.warning);
      expect(palette.textForeground, AppColors.textForeground);
      expect(palette.textMutedForeground, AppColors.textMutedForeground);
      expect(palette.textPrimaryForeground, AppColors.textPrimaryForeground);
      expect(palette.shadowSm, AppColors.shadowSm);
      expect(palette.shadowMd, AppColors.shadowMd);
      expect(palette.shadowPrimary, AppColors.shadowPrimary);
      expect(palette.gradient.colors, AppColors.gradient.colors);
    });
  });

  group('AppPalette.highContrast (FR-005, SC-003)', () {
    const palette = AppPalette.highContrast;
    const aaa = 7.0;

    test('texto sobre fundo, cartão e campo ≥ 7:1', () {
      for (final Color surface in [
        palette.background,
        palette.card,
        palette.input,
      ]) {
        expect(contrast(palette.textForeground, surface), greaterThan(aaa));
        expect(
          contrast(palette.textMutedForeground, surface),
          greaterThan(aaa),
        );
      }
    });

    test('cores usadas como texto ou ícone sobre o fundo ≥ 7:1', () {
      for (final Color color in [
        palette.primary,
        palette.secondary,
        palette.destructive,
        palette.success,
        palette.warning,
      ]) {
        expect(contrast(color, palette.background), greaterThan(aaa));
      }
    });

    test('texto claro sobre botões ≥ 7:1', () {
      for (final Color button in [
        palette.primary,
        palette.primaryGlow,
        palette.secondary,
      ]) {
        expect(
          contrast(palette.textPrimaryForeground, button),
          greaterThan(aaa),
        );
      }
    });

    test('bordas ≥ 3:1 sobre o fundo', () {
      expect(contrast(palette.border, palette.background), greaterThan(3));
    });

    test('sem sombras: a borda separa os cartões', () {
      expect(palette.shadowSm, isEmpty);
      expect(palette.shadowMd, isEmpty);
      expect(palette.shadowPrimary, isEmpty);
    });
  });

  group('ThemeExtension', () {
    test('copyWith troca só o campo pedido', () {
      final copy = AppPalette.light.copyWith(primary: Colors.black);

      expect(copy.primary, Colors.black);
      expect(copy.secondary, AppPalette.light.secondary);
    });

    test('lerp nas pontas devolve cada paleta', () {
      expect(
        AppPalette.light.lerp(AppPalette.highContrast, 1).primary,
        AppPalette.highContrast.primary,
      );
      expect(
        AppPalette.light.lerp(AppPalette.highContrast, 0).primary,
        AppPalette.light.primary,
      );
    });
  });

  group('AppTheme', () {
    test('cada tema carrega a sua paleta', () {
      expect(AppTheme.lightTheme.extension<AppPalette>(), AppPalette.light);
      expect(
        AppTheme.highContrastTheme.extension<AppPalette>(),
        AppPalette.highContrast,
      );
    });

    test('alto contraste usa as cores fortes no Material', () {
      final ThemeData theme = AppTheme.highContrastTheme;

      expect(theme.colorScheme.primary, AppPalette.highContrast.primary);
      expect(theme.scaffoldBackgroundColor, AppPalette.highContrast.background);
      expect(
        theme.textTheme.bodyMedium!.color,
        AppPalette.highContrast.textMutedForeground,
      );
    });

    testWidgets('context.colors lê a paleta do tema em uso', (tester) async {
      late AppPalette read;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.highContrastTheme,
          home: Builder(
            builder: (context) {
              read = context.colors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(read, AppPalette.highContrast);
    });

    testWidgets('sem a extensão no tema, cai na paleta light', (tester) async {
      late AppPalette read;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              read = context.colors;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(read, AppPalette.light);
    });
  });
}
