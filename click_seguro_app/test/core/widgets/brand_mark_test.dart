import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_theme.dart';
import 'package:click_seguro_app/core/widgets/brand_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Rect _viewBox = Rect.fromLTWH(88, 440, 444, 492);
const Color _red = Color(0xFFFE3152);

/// Pinta a marca em escala 1 (um pixel por unidade do `viewBox`) e devolve o
/// alfa de cada ponto pedido, em coordenadas do `viewBox`.
Future<List<int>> _alphaAt(
  WidgetTester tester,
  BrandMarkPainter painter,
  List<Offset> points,
) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), _viewBox.size);
  final ui.Picture picture = recorder.endRecording();
  return (await tester.runAsync(() async {
    final ui.Image image = await picture.toImage(444, 492);
    final ByteData data = (await image.toByteData())!;
    return <int>[
      for (final Offset point in points)
        data.getUint8(
          (((point.dy - _viewBox.top).round() * 444) +
                      (point.dx - _viewBox.left).round()) *
                  4 +
              3,
        ),
    ];
  }))!;
}

void main() {
  group('BrandMarkPaths', () {
    test('o escudo tem os limites do SVG oficial', () {
      expect(
        BrandMarkPaths.shield.getBounds(),
        const Rect.fromLTRB(111, 464, 509, 906),
      );
    });

    test('as duas metades partem do topo e chegam à ponta', () {
      expect(BrandMarkPaths.shieldHalves, hasLength(2));
      for (final ui.Path half in BrandMarkPaths.shieldHalves) {
        final ui.PathMetric metric = half.computeMetrics().single;
        expect(metric.getTangentForOffset(0)!.position, const Offset(310, 464));
        expect(
          metric.getTangentForOffset(metric.length)!.position,
          const Offset(310, 906),
        );
      }
    });

    test('a silhueta e os cinco detalhes seguem o SVG oficial', () {
      final Rect elder = BrandMarkPaths.elder.getBounds();

      expect(elder.left, 140);
      expect(elder.top, 532);
      expect(elder.bottom, 960);
      expect(BrandMarkPaths.details, hasLength(5));
    });
  });

  group('BrandMarkPainter', () {
    testWidgets('pinta a marca completa num CustomPaint 120x133', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Center(
          child: SizedBox(
            width: 120,
            height: 133,
            child: CustomPaint(painter: BrandMarkPainter(color: _red)),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    test('shouldRepaint só quando cor ou progressos mudam', () {
      const BrandMarkPainter base = BrandMarkPainter(color: _red);

      expect(base.shouldRepaint(const BrandMarkPainter(color: _red)), isFalse);
      expect(
        base.shouldRepaint(const BrandMarkPainter(color: Color(0xFF9E0019))),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const BrandMarkPainter(color: _red, strokeProgress: 0.5),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const BrandMarkPainter(color: _red, elderProgress: 0.5),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(const BrandMarkPainter(color: _red, tipProgress: 1)),
        isTrue,
      );
    });

    testWidgets(
      'marca completa: escudo e silhueta pintados, detalhes vazados',
      (tester) async {
        final List<int> alpha = await _alphaAt(
          tester,
          const BrandMarkPainter(color: _red),
          const [Offset(111, 580), Offset(300, 580), Offset(300, 634)],
        );

        expect(alpha[0], 255, reason: 'traço do escudo');
        expect(alpha[1], 255, reason: 'silhueta');
        expect(alpha[2], 0, reason: 'óculos recortado da silhueta');
      },
    );

    testWidgets('strokeProgress 0 não desenha o escudo, só a silhueta', (
      tester,
    ) async {
      final List<int> alpha = await _alphaAt(
        tester,
        const BrandMarkPainter(color: _red, strokeProgress: 0),
        const [Offset(111, 580), Offset(509, 580), Offset(300, 580)],
      );

      expect(alpha, [0, 0, 255]);
    });

    testWidgets('strokeProgress 0 e elderProgress 0 não pintam nada', (
      tester,
    ) async {
      final List<int> alpha = await _alphaAt(
        tester,
        const BrandMarkPainter(
          color: _red,
          strokeProgress: 0,
          elderProgress: 0,
        ),
        const [Offset(111, 580), Offset(300, 580), Offset(310, 464)],
      );

      expect(alpha, [0, 0, 0]);
    });

    testWidgets('o traço cresce do topo pelas duas laterais', (tester) async {
      final List<int> alpha = await _alphaAt(
        tester,
        const BrandMarkPainter(
          color: _red,
          strokeProgress: 0.3,
          elderProgress: 0,
        ),
        const [
          Offset(310, 464),
          Offset(111, 590),
          Offset(509, 590),
          Offset(310, 906),
        ],
      );

      expect(alpha[0], 255, reason: 'topo, onde o traço começa');
      expect(alpha[1], 0, reason: 'lateral esquerda ainda por desenhar');
      expect(alpha[2], 0, reason: 'lateral direita ainda por desenhar');
      expect(alpha[3], 0, reason: 'ponta ainda por desenhar');
    });

    testWidgets('elderProgress 0,5 deixa a silhueta translúcida e mais baixa', (
      tester,
    ) async {
      final List<int> alpha = await _alphaAt(
        tester,
        const BrandMarkPainter(
          color: _red,
          strokeProgress: 0,
          elderProgress: 0.5,
        ),
        const [Offset(300, 580), Offset(300, 760)],
      );

      expect(alpha[0], 0, reason: 'a cabeça desceu 60 unidades');
      expect(alpha[1], inInclusiveRange(100, 160));
    });

    testWidgets('tipProgress desenha só o ponto do topo', (tester) async {
      final List<int> alpha = await _alphaAt(
        tester,
        const BrandMarkPainter(
          color: _red,
          strokeProgress: 0,
          elderProgress: 0,
          tipProgress: 1,
        ),
        const [Offset(310, 464), Offset(310, 500)],
      );

      expect(alpha, [255, 0]);
    });
  });

  group('BrandMark', () {
    testWidgets('ocupa o tamanho pedido, na cor primary do tema', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Center(child: BrandMark(size: 96)),
        ),
      );

      expect(tester.getSize(find.byType(BrandMark)), const Size(96, 96));
      final BrandMarkPainter painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(BrandMark),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as BrandMarkPainter;
      expect(painter.color, AppPalette.light.primary);
    });

    testWidgets('uma cor informada vence a do tema', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Center(child: BrandMark(size: 48, color: Colors.white)),
        ),
      );

      final BrandMarkPainter painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(BrandMark),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as BrandMarkPainter;
      expect(painter.color, Colors.white);
    });
  });
}
