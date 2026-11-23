import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/brand_mark.dart';
import 'package:click_seguro_app/core/widgets/brand_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BrandWavePainter _wavePainter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(BrandWave),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as BrandWavePainter;

void main() {
  group('logoRectFor', () {
    test('marca centrada na largura, na proporção do viewBox', () {
      final Rect rect = BrandScene.logoRectFor(width: 390, viewportHeight: 844);

      expect(rect.center.dx, 195);
      expect(
        rect.width / rect.height,
        closeTo(
          BrandMarkPaths.viewBox.width / BrandMarkPaths.viewBox.height,
          1e-6,
        ),
      );
      expect(rect.width, 164);
      expect(rect.top, closeTo(844 * 0.28, 1e-6));
    });

    test('encolhe em tela curta, sem passar do mínimo', () {
      final Rect rect = BrandScene.logoRectFor(width: 320, viewportHeight: 480);

      expect(rect.width, 96);
      expect(rect.center.dx, 160);
    });

    test('respeita o recuo do topo (barra de status)', () {
      final Rect rect = BrandScene.logoRectFor(
        width: 390,
        viewportHeight: 200,
        topInset: 60,
      );

      expect(rect.top, 60 + AppSpacing.s6);
    });
  });

  test('o nome fica 32 abaixo da marca, e o slogan 8 abaixo do nome', () {
    final Rect logo = BrandScene.logoRectFor(width: 390, viewportHeight: 844);

    expect(BrandScene.titleTopFor(logo), logo.bottom + AppSpacing.s7);
    expect(BrandScene.taglineGap, AppSpacing.s2);
  });

  group('wavePath', () {
    test('com progresso 1, a onda da frente fica no rodapé', () {
      const Size size = Size(390, 844);
      final Rect bounds = BrandScene.wavePath(
        size,
        edge: BrandScene.frontEdge,
        top: size.height - BrandScene.footerHeight,
        progress: 1,
        below: true,
      ).getBounds();

      // A borda mais alta da onda da frente fica dentro do rodapé de 110.
      expect(bounds.top, greaterThanOrEqualTo(size.height - 110));
      expect(bounds.left, 0);
      expect(bounds.right, 390);
    });

    test('com progresso 0, a onda cobre a tela toda', () {
      const Size size = Size(390, 844);
      final Path path = BrandScene.wavePath(
        size,
        edge: BrandScene.frontEdge,
        top: size.height - BrandScene.footerHeight,
        progress: 0,
        below: true,
      );

      expect(path.contains(const Offset(195, 10)), isTrue);
    });
  });

  group('BrandWave', () {
    testWidgets('as duas ondas paradas, nas cores do tema, sem semântica', (
      tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Align(
            alignment: Alignment.bottomCenter,
            child: BrandWave(),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(BrandWave)).height,
        BrandScene.glowFooterHeight,
      );
      final BrandWavePainter painter = _wavePainter(tester);
      expect(painter.front, AppPalette.light.primary);
      expect(painter.glow, AppPalette.light.primaryGlow);
      expect(tester.getSemantics(find.byType(BrandWave)).label, isEmpty);
      semantics.dispose();
    });

    testWidgets('no alto contraste usa as cores do alto contraste', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.highContrastTheme,
          home: const Align(
            alignment: Alignment.bottomCenter,
            child: BrandWave(),
          ),
        ),
      );

      final BrandWavePainter painter = _wavePainter(tester);
      expect(painter.front, AppPalette.highContrast.primary);
      expect(painter.glow, AppPalette.highContrast.primaryGlow);
    });
  });
}
