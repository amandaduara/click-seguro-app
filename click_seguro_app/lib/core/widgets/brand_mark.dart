import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Paths oficiais da marca, transcritos de
/// assets/branding/click_seguro_logo.svg (`viewBox` `88 440 444 492`).
abstract final class BrandMarkPaths {
  static const Rect viewBox = Rect.fromLTWH(88, 440, 444, 492);

  /// Linha central do traço do escudo (largura 32), fechada.
  static final Path shield = Path()
    ..moveTo(310, 464)
    ..cubicTo(252, 500, 182, 526, 111, 536)
    ..lineTo(111, 620)
    ..cubicTo(111, 762, 200, 852, 310, 906)
    ..cubicTo(420, 852, 509, 762, 509, 620)
    ..lineTo(509, 536)
    ..cubicTo(438, 526, 368, 500, 310, 464)
    ..close();

  /// As duas metades do escudo, do topo (310,464) à ponta (310,906): a
  /// esquerda e a direita. O traço da abertura cresce pelas duas.
  static final List<Path> shieldHalves = [
    Path()
      ..moveTo(310, 464)
      ..cubicTo(252, 500, 182, 526, 111, 536)
      ..lineTo(111, 620)
      ..cubicTo(111, 762, 200, 852, 310, 906),
    Path()
      ..moveTo(310, 464)
      ..cubicTo(368, 500, 438, 526, 509, 536)
      ..lineTo(509, 620)
      ..cubicTo(509, 762, 420, 852, 310, 906),
  ];

  /// Silhueta do idoso; só aparece dentro do escudo.
  static final Path elder = Path()
    ..moveTo(160, 815)
    ..lineTo(238, 710)
    ..cubicTo(248, 701, 254, 694, 258, 686)
    ..cubicTo(226, 662, 215, 632, 217, 605)
    ..cubicTo(220, 561, 259, 532, 302, 532)
    ..cubicTo(345, 532, 378, 556, 388, 590)
    ..lineTo(392, 615)
    ..cubicTo(396, 631, 405, 648, 416, 660)
    ..cubicTo(419, 667, 412, 671, 400, 673)
    ..lineTo(402, 684)
    ..cubicTo(400, 690, 397, 695, 398, 700)
    ..cubicTo(396, 708, 386, 713, 366, 713)
    ..lineTo(355, 716)
    ..cubicTo(358, 736, 366, 758, 375, 792)
    ..lineTo(392, 862)
    ..lineTo(392, 960)
    ..lineTo(140, 960)
    ..close();

  /// Óculos, orelha e gola: traços recortados da silhueta, com a largura de
  /// cada um.
  static final List<({Path path, double width})> details = [
    (
      path: Path()
        ..moveTo(268, 634)
        ..lineTo(361, 634),
      width: 7,
    ),
    (
      path: Path()
        ..addOval(Rect.fromCircle(center: const Offset(377, 638), radius: 16)),
      width: 7,
    ),
    (
      path: Path()
        ..moveTo(393, 633)
        ..lineTo(404, 628),
      width: 6,
    ),
    (
      path: Path()
        ..moveTo(284, 641)
        ..cubicTo(264, 630, 256, 664, 270, 680)
        ..cubicTo(277, 688, 287, 690, 293, 684),
      width: 7,
    ),
    (
      path: Path()
        ..moveTo(238, 712)
        ..lineTo(333, 779)
        ..lineTo(352, 766),
      width: 5,
    ),
  ];

  static const double strokeWidth = 32;
  static const Offset shieldTop = Offset(310, 464);

  /// Quanto a silhueta sobe, em unidades do `viewBox`, ao entrar no escudo.
  static const double elderRise = 120;
}

/// Desenha a marca na [color] dada, ajustada ao tamanho do canvas (como
/// `BoxFit.contain`). Os progressos permitem animar a abertura: [strokeProgress]
/// faz o traço do escudo crescer do topo pelas duas laterais; [elderProgress]
/// sobe e revela a silhueta; [tipProgress] é o ponto que pousa no topo antes
/// do traço. Valores padrão desenham a marca pronta.
class BrandMarkPainter extends CustomPainter {
  const BrandMarkPainter({
    required this.color,
    this.strokeProgress = 1,
    this.elderProgress = 1,
    this.tipProgress = 0,
  });

  final Color color;
  final double strokeProgress;
  final double elderProgress;
  final double tipProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = math.min(
      size.width / BrandMarkPaths.viewBox.width,
      size.height / BrandMarkPaths.viewBox.height,
    );
    canvas
      ..save()
      ..translate(
        (size.width - BrandMarkPaths.viewBox.width * scale) / 2,
        (size.height - BrandMarkPaths.viewBox.height * scale) / 2,
      )
      ..scale(scale)
      ..translate(-BrandMarkPaths.viewBox.left, -BrandMarkPaths.viewBox.top);

    final double elder = elderProgress.clamp(0.0, 1.0);
    if (elder > 0) {
      _paintElder(canvas, elder);
    }
    _paintShield(canvas);
    if (tipProgress > 0) {
      canvas.drawCircle(
        BrandMarkPaths.shieldTop,
        BrandMarkPaths.strokeWidth / 2 * tipProgress,
        Paint()..color = color,
      );
    }
    canvas.restore();
  }

  // Silhueta recortada pelo escudo; os detalhes saem da própria camada, para
  // deixar ver o que está atrás da marca.
  void _paintElder(Canvas canvas, double progress) {
    canvas
      ..save()
      ..clipPath(BrandMarkPaths.shield)
      ..saveLayer(
        BrandMarkPaths.viewBox,
        Paint()..color = Color.fromRGBO(0, 0, 0, progress),
      )
      ..translate(0, (1 - progress) * BrandMarkPaths.elderRise)
      ..drawPath(BrandMarkPaths.elder, Paint()..color = color);
    for (final detail in BrandMarkPaths.details) {
      canvas.drawPath(
        detail.path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = detail.width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..blendMode = BlendMode.clear,
      );
    }
    canvas
      ..restore()
      ..restore();
  }

  void _paintShield(Canvas canvas) {
    final double progress = strokeProgress.clamp(0.0, 1.0);
    if (progress <= 0) {
      return;
    }
    final Paint stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = BrandMarkPaths.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final Path half in BrandMarkPaths.shieldHalves) {
      final PathMetric metric = half.computeMetrics().first;
      canvas.drawPath(metric.extractPath(0, metric.length * progress), stroke);
    }
  }

  @override
  bool shouldRepaint(BrandMarkPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeProgress != oldDelegate.strokeProgress ||
      elderProgress != oldDelegate.elderProgress ||
      tipProgress != oldDelegate.tipProgress;
}

/// A marca na cor do tema ([AppPalette.primary], que segue o alto contraste).
/// Decorativa: o nome da marca vem escrito ao lado.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.size, this.color});

  final double size;

  /// Sem ela, a cor `primary` do tema em uso.
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: BrandMarkPainter(color: color ?? context.colors.primary),
    ),
  );
}
