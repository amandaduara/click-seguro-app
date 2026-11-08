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

/// Pares de texto e fundo usados pelos componentes (FR-001, SC-002).
void expectTextPairs(AppPalette p, double minimum) {
  final Map<String, (Color, Color)> pairs = {
    for (final MapEntry<String, Color> text in {
      'textForeground': p.textForeground,
      'textBody': p.textBody,
      'textMutedForeground': p.textMutedForeground,
    }.entries)
      for (final MapEntry<String, Color> surface in {
        'background': p.background,
        'surface': p.surface,
        'surfaceStrong': p.surfaceStrong,
        'input': p.input,
      }.entries)
        '${text.key} / ${surface.key}': (text.value, surface.value),
    'branco / primary': (p.textPrimaryForeground, p.primary),
    'branco / primaryPressed': (p.textPrimaryForeground, p.primaryPressed),
    'branco / secondary': (p.textPrimaryForeground, p.secondary),
    'primaryPressed / primarySoft': (p.primaryPressed, p.primarySoft),
    'success / successSoft': (p.success, p.successSoft),
    'warning / warningSoft': (p.warning, p.warningSoft),
    'info / infoSoft': (p.info, p.infoSoft),
    'primary / background': (p.primary, p.background),
    'destructive / background': (p.destructive, p.background),
    'success / background': (p.success, p.background),
    'warning / background': (p.warning, p.background),
    'info / background': (p.info, p.background),
  };
  for (final MapEntry<String, (Color, Color)> pair in pairs.entries) {
    expect(
      contrast(pair.value.$1, pair.value.$2),
      greaterThanOrEqualTo(minimum),
      reason: pair.key,
    );
  }
}

void main() {
  group('AppPalette.light (FR-001)', () {
    const palette = AppPalette.light;

    test('usa os valores do redesign 2.0 (AppColors)', () {
      expect(palette.primary, const Color(0xFFE31C3D));
      expect(palette.primaryPressed, const Color(0xFFC2112F));
      expect(palette.primarySoft, const Color(0xFFFFE8EB));
      expect(palette.secondary, const Color(0xFF1B2440));
      expect(palette.textForeground, const Color(0xFF1B2440));
      expect(palette.textBody, const Color(0xFF3D4457));
      expect(palette.textMutedForeground, const Color(0xFF5E6577));
      expect(palette.background, const Color(0xFFFFFFFF));
      expect(palette.surface, const Color(0xFFF7F5F0));
      expect(palette.surfaceStrong, const Color(0xFFEFEBE3));
      expect(palette.border, const Color(0xFFE4E1DA));
      expect(palette.success, const Color(0xFF0F7B4F));
      expect(palette.warning, const Color(0xFF8F5600));
      expect(palette.info, const Color(0xFF2554C7));
      expect(palette.destructive, const Color(0xFFC4122F));
      expect(palette.primary, AppColors.primary);
      expect(palette.shadow, AppColors.shadow);
    });

    test('texto sobre fundo ≥ 4,5:1 (WCAG AA)', () {
      expectTextPairs(palette, 4.5);
    });

    test('contorno dos campos ≥ 3:1 sobre o fundo', () {
      expect(contrast(palette.inputBorder, palette.background), greaterThan(3));
    });

    test('tem a sombra única', () {
      expect(palette.shadow, isNotEmpty);
    });
  });

  group('AppPalette.highContrast (RF-039, FR-002)', () {
    const palette = AppPalette.highContrast;

    test('texto sobre fundo ≥ 7:1 (WCAG AAA)', () {
      expectTextPairs(palette, 7);
    });

    test('bordas e contorno dos campos ≥ 3:1 sobre o fundo', () {
      expect(contrast(palette.border, palette.background), greaterThan(3));
      expect(contrast(palette.inputBorder, palette.background), greaterThan(3));
    });

    test('suaves e pastéis viram branco', () {
      for (final Color color in [
        palette.primarySoft,
        palette.successSoft,
        palette.warningSoft,
        palette.infoSoft,
        palette.pastelPeach,
        palette.pastelSage,
        palette.pastelSky,
        palette.pastelButter,
        palette.pastelLilac,
      ]) {
        expect(color, const Color(0xFFFFFFFF));
      }
    });

    test('sem sombras: a borda separa os cartões', () {
      expect(palette.shadow, isEmpty);
    });
  });

  group('ThemeExtension', () {
    test('copyWith troca só o campo pedido', () {
      final copy = AppPalette.light.copyWith(primary: Colors.black);

      expect(copy.primary, Colors.black);
      expect(copy.secondary, AppPalette.light.secondary);
      expect(copy.surface, AppPalette.light.surface);
    });

    test('lerp nas pontas devolve cada paleta', () {
      expect(
        AppPalette.light.lerp(AppPalette.highContrast, 1),
        AppPalette.highContrast,
      );
      expect(
        AppPalette.light.lerp(AppPalette.highContrast, 0),
        AppPalette.light,
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
        AppPalette.highContrast.textBody,
      );
    });

    test('usa a fonte Inter (R2)', () {
      expect(AppTheme.lightTheme.textTheme.bodyMedium!.fontFamily, 'Inter');
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
