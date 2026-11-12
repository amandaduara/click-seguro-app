import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/widgets/brand_mark.dart';
import 'package:click_seguro_app/modules/splash/presentation/widgets/splash_scene_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _screen = Size(390, 844);
final Rect _logoRect = SplashScenePainter.logoRectFor(
  width: _screen.width,
  viewportHeight: _screen.height,
);

SplashScenePainter _painter(
  double t, {
  double breath = 0,
  AppPalette colors = AppPalette.light,
}) => SplashScenePainter(
  t: t,
  breath: breath,
  colors: colors,
  logoRect: _logoRect,
);

double _ms(double milliseconds) => milliseconds / 1800;

/// Cor (ARGB) de cada ponto da cena pintada em [_screen].
Future<List<Color>> _colorsAt(
  WidgetTester tester,
  SplashScenePainter painter,
  List<Offset> points,
) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), _screen);
  final ui.Picture picture = recorder.endRecording();
  return (await tester.runAsync(() async {
    final ui.Image image = await picture.toImage(390, 844);
    final ByteData data = (await image.toByteData())!;
    return <Color>[
      for (final Offset point in points)
        () {
          final int i = (point.dy.round() * 390 + point.dx.round()) * 4;
          return Color.fromARGB(
            data.getUint8(i + 3),
            data.getUint8(i),
            data.getUint8(i + 1),
            data.getUint8(i + 2),
          );
        }(),
    ];
  }))!;
}

/// Ponto da cena que corresponde a ([x], [y]) do `viewBox` da marca.
Offset _inLogo(double x, double y) {
  final double scale = _logoRect.width / BrandMarkPaths.viewBox.width;
  return Offset(
    _logoRect.left + (x - BrandMarkPaths.viewBox.left) * scale,
    _logoRect.top + (y - BrandMarkPaths.viewBox.top) * scale,
  );
}

void main() {
  final Color primary = AppPalette.light.primary;
  final Color background = AppPalette.light.background;

  group('logoRectFor', () {
    test('marca centrada na largura, na proporção do viewBox', () {
      final Rect rect = SplashScenePainter.logoRectFor(
        width: 390,
        viewportHeight: 844,
      );

      expect(rect.center.dx, 195);
      expect(
        rect.width / rect.height,
        closeTo(
          BrandMarkPaths.viewBox.width / BrandMarkPaths.viewBox.height,
          1e-6,
        ),
      );
      expect(rect.width, 164);
    });

    test('encolhe em tela curta', () {
      final Rect rect = SplashScenePainter.logoRectFor(
        width: 320,
        viewportHeight: 480,
      );

      expect(rect.width, lessThan(164));
      expect(rect.width, greaterThanOrEqualTo(96));
    });

    test('respeita o recuo do topo (barra de status)', () {
      final Rect rect = SplashScenePainter.logoRectFor(
        width: 390,
        viewportHeight: 200,
        topInset: 60,
      );

      expect(rect.top, greaterThanOrEqualTo(60));
    });
  });

  group('pintura', () {
    for (final double t in [0, 0.3, 0.5, 0.75, 1]) {
      testWidgets('t = $t pinta sem exceção', (tester) async {
        await tester.pumpWidget(
          SizedBox.fromSize(
            size: _screen,
            child: CustomPaint(painter: _painter(t)),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('pinta também com as cores do alto contraste', (tester) async {
      final List<Color> colors = await _colorsAt(
        tester,
        _painter(1, colors: AppPalette.highContrast),
        const [Offset(195, 843)],
      );

      expect(colors.single, AppPalette.highContrast.primary);
    });

    testWidgets('t = 0 não pinta nada (o toque ainda nem apareceu)', (
      tester,
    ) async {
      final List<Color> colors = await _colorsAt(tester, _painter(0), [
        const Offset(10, 10),
        const Offset(195, 400),
        const Offset(195, 843),
        _logoRect.center,
      ]);

      expect(colors.map((c) => c.a), everyElement(0));
    });

    testWidgets('a mancha cobre a tela inteira antes da onda descer', (
      tester,
    ) async {
      final List<Color> colors = await _colorsAt(tester, _painter(_ms(1000)), [
        const Offset(2, 2),
        const Offset(387, 2),
        const Offset(2, 841),
        const Offset(387, 841),
        const Offset(195, 700),
      ]);

      expect(colors, everyElement(primary));
    });

    testWidgets('em t = 1 a onda fica no rodapé e a mancha não aparece', (
      tester,
    ) async {
      final List<Color> colors = await _colorsAt(tester, _painter(1), [
        const Offset(2, 2),
        const Offset(387, 2),
        const Offset(195, 450),
        const Offset(195, 700),
        const Offset(195, 843),
        const Offset(2, 843),
      ]);

      expect(colors[0].a, 0, reason: 'canto de cima livre (sem mancha)');
      expect(colors[1].a, 0);
      expect(colors[2].a, 0);
      expect(colors[3].a, 0, reason: 'a onda só ocupa o rodapé');
      expect(colors[4], primary);
      expect(colors[5].a, 1);
    });

    testWidgets('a faixa de brilho aparece acima da onda enquanto ela desce', (
      tester,
    ) async {
      final List<Color> colors = await _colorsAt(tester, _painter(_ms(1250)), [
        const Offset(20, 10),
        const Offset(20, 150),
        const Offset(20, 835),
      ]);

      expect(colors[0].a, 0, reason: 'topo já revelado');
      expect(colors[1], AppPalette.light.primaryGlow);
      expect(colors[2], primary);
    });

    testWidgets('a marca está em primary no final', (tester) async {
      final List<Color> colors = await _colorsAt(tester, _painter(1), [
        _inLogo(111, 580),
        _inLogo(509, 580),
        _inLogo(300, 580),
        _inLogo(300, 634),
      ]);

      expect(colors[0], primary, reason: 'traço do escudo');
      expect(colors[1], primary);
      expect(colors[2], primary, reason: 'silhueta');
      expect(colors[3].a, 0, reason: 'óculos vazado');
    });

    testWidgets('sobre o vermelho a marca é desenhada em background', (
      tester,
    ) async {
      final List<Color> colors = await _colorsAt(tester, _painter(_ms(1000)), [
        _inLogo(111, 580),
        _inLogo(509, 580),
      ]);

      expect(colors, everyElement(background));
    });

    testWidgets('a marca troca de cor onde a onda já passou', (tester) async {
      final double progress = _ms(1250);
      final List<Color> colors = await _colorsAt(tester, _painter(progress), [
        _inLogo(310, 470),
        _inLogo(310, 900),
      ]);

      // No meio da descida, a onda ainda está sobre a parte de baixo.
      expect(colors[0], primary, reason: 'topo já revelado');
      expect(colors[1], background, reason: 'ponta ainda sob o vermelho');
    });

    testWidgets('a respiração aumenta a marca', (tester) async {
      final Offset outside = _inLogo(111 - 16, 580) + const Offset(-1.5, 0);
      final List<Color> still = await _colorsAt(tester, _painter(1), [outside]);
      final List<Color> breathing = await _colorsAt(
        tester,
        _painter(1, breath: 1),
        [outside],
      );

      expect(still.single.a, 0);
      expect(breathing.single, primary);
    });
  });

  group('shouldRepaint', () {
    test('só quando t, breath, cores ou posição da marca mudam', () {
      final SplashScenePainter base = _painter(0.5, breath: 0.2);

      expect(base.shouldRepaint(_painter(0.5, breath: 0.2)), isFalse);
      expect(base.shouldRepaint(_painter(0.6, breath: 0.2)), isTrue);
      expect(base.shouldRepaint(_painter(0.5, breath: 0.3)), isTrue);
      expect(
        base.shouldRepaint(
          _painter(0.5, breath: 0.2, colors: AppPalette.highContrast),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          SplashScenePainter(
            t: 0.5,
            breath: 0.2,
            colors: AppPalette.light,
            logoRect: _logoRect.shift(const Offset(0, 10)),
          ),
        ),
        isTrue,
      );
    });
  });
}
