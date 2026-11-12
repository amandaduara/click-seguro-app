import 'dart:math' as math;

import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/widgets/brand_mark.dart';
import 'package:flutter/material.dart';

/// Linha do tempo da abertura "Mancha e onda" (specs/023 R1): um único
/// progresso `t` de 0 a 1 em [total], cortado em fases por `Interval`s.
abstract final class SplashTimeline {
  static const Duration total = Duration(milliseconds: 1800);

  /// A onda de brilho vem 60 ms atrás da onda principal.
  static const double glowLag = 60 / 1800;

  /// Instante (em `t`) em que a mancha cobre a tela e a onda assume.
  static const double blobStart = 200 / 1800;
  static const double blobEnd = 700 / 1800;

  // Curva do protótipo aprovado (cubic-bezier 0,4 0 0,2 1): `AppMotion.standard`
  // é mais seca no começo e a onda passaria pelo logo em poucos quadros.
  static const Curve signature = Curves.fastOutSlowIn;

  static Interval _between(int beginMs, int endMs, Curve curve) =>
      Interval(beginMs / 1800, endMs / 1800, curve: curve);

  static final Interval touch = _between(0, 400, Curves.linear);
  static final Interval blob = _between(200, 700, Curves.linear);
  static final Interval tip = _between(500, 700, AppMotion.emphasis);
  static final Interval stroke = _between(560, 1000, signature);
  static final Interval elder = _between(850, 1150, AppMotion.enter);
  static final Interval wave = _between(1100, 1550, signature);
  static final Interval title = _between(1400, 1650, AppMotion.enter);
  static final Interval tagline = _between(1550, 1800, AppMotion.enter);
}

/// Cena da abertura: toque, mancha, onda e a marca, só com cores de
/// [AppPalette]. Desenha em coordenadas da tela; [logoRect] é onde a marca
/// fica (o layout deixa o mesmo espaço para ela).
///
/// A marca é desenhada duas vezes: em `background` onde o vermelho ainda
/// cobre e em `primary` onde a onda já passou (specs/023 R2).
class SplashScenePainter extends CustomPainter {
  const SplashScenePainter({
    required this.t,
    required this.breath,
    required this.colors,
    required this.logoRect,
  });

  /// Progresso da abertura, de 0 a 1.
  final double t;

  /// Respiração da marca, de 0 a 1 (escala 1 a 1,035).
  final double breath;
  final AppPalette colors;
  final Rect logoRect;

  // Larguras de referência do protótipo (390 px de largura, 164 px de marca).
  static const double _referenceWidth = 390;
  static const double _maxLogoWidth = 164;
  static const double _minLogoWidth = 96;
  static const double _footerHeight = 110;
  static const double _glowFooterHeight = 136;
  static const double _breathScale = 0.035;

  // Bordas das ondas (x, y de controle em 390 px; y a partir do topo da onda).
  static const List<double> _frontEdge = [
    0, 52, 68, 14, 128, 18, 196, 54, 262, 90, 322, 104, 390, 84, //
  ];
  static const List<double> _glowEdge = [
    0, 84, 60, 112, 120, 116, 190, 84, 262, 50, 322, 26, 390, 52, //
  ];

  /// Onde a marca fica numa tela de [width] x [viewportHeight]: centrada na
  /// largura, a 28% da altura (abaixo de [topInset]), e menor em tela curta.
  static Rect logoRectFor({
    required double width,
    required double viewportHeight,
    double topInset = 0,
  }) {
    final double logoWidth = (viewportHeight * 0.2).clamp(
      _minLogoWidth,
      _maxLogoWidth,
    );
    final double logoHeight =
        logoWidth *
        BrandMarkPaths.viewBox.height /
        BrandMarkPaths.viewBox.width;
    return Rect.fromLTWH(
      (width - logoWidth) / 2,
      math.max(viewportHeight * 0.28, topInset + 24),
      logoWidth,
      logoHeight,
    );
  }

  double get _unit => logoRect.width / BrandMarkPaths.viewBox.width;

  Offset _inLogo(double x, double y) => Offset(
    logoRect.left + (x - BrandMarkPaths.viewBox.left) * _unit,
    logoRect.top + (y - BrandMarkPaths.viewBox.top) * _unit,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final double wave = SplashTimeline.wave.transform(t);
    final bool settled = wave >= 1;

    Path? red;
    Path? revealed;
    if (t < SplashTimeline.blobEnd) {
      if (t >= SplashTimeline.blobStart) {
        red = _blobPath(size);
        canvas.drawPath(red, Paint()..color = colors.primary);
      }
    } else {
      final double glowWave = SplashTimeline.wave.transform(
        math.max(0, t - SplashTimeline.glowLag),
      );
      canvas.drawPath(
        _wavePath(
          size,
          edge: _glowEdge,
          top: size.height - _glowFooterHeight,
          progress: glowWave,
          below: true,
        ),
        Paint()..color = colors.primaryGlow,
      );
      red = _wavePath(
        size,
        edge: _frontEdge,
        top: size.height - _footerHeight,
        progress: wave,
        below: true,
      );
      canvas.drawPath(red, Paint()..color = colors.primary);
      if (!settled) {
        revealed = _wavePath(
          size,
          edge: _frontEdge,
          top: size.height - _footerHeight,
          progress: wave,
          below: false,
        );
      }
    }

    _paintTouch(canvas);

    if (settled) {
      _paintLogo(canvas, colors.primary);
    } else {
      if (red != null) {
        _paintLogo(canvas, colors.background, clip: red);
      }
      if (revealed != null) {
        _paintLogo(canvas, colors.primary, clip: revealed);
      }
    }
  }

  // O toque aparece, pressiona e some, no centro do escudo.
  void _paintTouch(Canvas canvas) {
    final double u = SplashTimeline.touch.transform(t);
    if (u <= 0 || u >= 1) {
      return;
    }
    final double scale = _keyframes(u, const [
      (0, 0.4),
      (0.32, 1),
      (0.52, 0.78),
      (0.74, 1),
      (1, 1),
    ], SplashTimeline.signature);
    final double opacity = _keyframes(u, const [
      (0, 0),
      (0.32, 1),
      (0.74, 1),
      (1, 0),
    ], SplashTimeline.signature);
    canvas.drawCircle(
      _inLogo(310, 685),
      38 * _unit * scale,
      Paint()..color = colors.primary.withValues(alpha: opacity),
    );
  }

  // Marca com o progresso da abertura; [clip] limita onde ela aparece.
  void _paintLogo(Canvas canvas, Color color, {Path? clip}) {
    final Offset pivot = logoRect.topLeft.translate(
      logoRect.width * 0.5,
      logoRect.height * 0.55,
    );
    canvas
      ..save()
      ..clipPath(clip ?? (Path()..addRect(logoRect.inflate(logoRect.width))))
      ..translate(pivot.dx, pivot.dy)
      ..scale(1 + _breathScale * breath)
      ..translate(-pivot.dx, -pivot.dy)
      ..translate(logoRect.left, logoRect.top);
    BrandMarkPainter(
      color: color,
      strokeProgress: SplashTimeline.stroke.transform(t),
      elderProgress: SplashTimeline.elder.transform(t),
      tipProgress: SplashTimeline.tip.transform(t),
    ).paint(canvas, logoRect.size);
    canvas.restore();
  }

  // Mancha de 8 pontos com bordas onduladas, a partir do centro do toque,
  // crescendo até passar da diagonal da tela.
  Path _blobPath(Size size) {
    const int points = 8;
    final double u = SplashTimeline.blob.transform(t);
    final Offset center = _inLogo(310, 685);
    final double farthest = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((corner) => (corner - center).distance).reduce(math.max);
    final double radius =
        farthest *
        1.25 *
        _keyframes(u, const [
          (0, 0.02),
          (0.333, 0.171),
          (0.646, 0.429),
          (1, 1),
        ], Curves.linear);
    final double wobble = 0.12 * math.sin(math.pi * u);
    final double turn = u * 70 * math.pi / 180;

    final List<Offset> ring = [
      for (int i = 0; i < points; i++)
        center +
            Offset.fromDirection(
              turn + i * 2 * math.pi / points,
              radius * (1 + wobble * math.sin(u * 4 * math.pi + i * 1.7)),
            ),
    ];
    final Path path = Path()..moveTo(ring.first.dx, ring.first.dy);
    for (int i = 0; i < points; i++) {
      final Offset before = ring[(i - 1 + points) % points];
      final Offset from = ring[i];
      final Offset to = ring[(i + 1) % points];
      final Offset after = ring[(i + 2) % points];
      final Offset c1 = from + (to - before) / 6;
      final Offset c2 = to - (after - from) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, to.dx, to.dy);
    }
    return path..close();
  }

  // Onda que desce da tela inteira até o rodapé: [below] é a área vermelha
  // (abaixo da borda); senão, a área já revelada (acima dela).
  Path _wavePath(
    Size size, {
    required List<double> edge,
    required double top,
    required double progress,
    required bool below,
  }) {
    final double sx = size.width / _referenceWidth;
    final double dy = -(size.height + 40) * (1 - progress);
    double x(int i) => edge[i] * sx;
    double y(int i) => top + dy + edge[i];

    final Path path = Path()
      ..moveTo(x(0), y(1))
      ..cubicTo(x(2), y(3), x(4), y(5), x(6), y(7))
      ..cubicTo(x(8), y(9), x(10), y(11), x(12), y(13));
    final double far = below ? size.height + 200 : -(size.height + 200);
    return path
      ..lineTo(size.width, far)
      ..lineTo(0, far)
      ..close();
  }

  // Interpola [frames] (progresso, valor) com [curve] em cada trecho.
  static double _keyframes(
    double u,
    List<(double, double)> frames,
    Curve curve,
  ) {
    for (int i = 1; i < frames.length; i++) {
      final (double endAt, double endValue) = frames[i];
      if (u <= endAt) {
        final (double beginAt, double beginValue) = frames[i - 1];
        final double local = (u - beginAt) / (endAt - beginAt);
        return beginValue +
            (endValue - beginValue) * curve.transform(local.clamp(0.0, 1.0));
      }
    }
    return frames.last.$2;
  }

  @override
  bool shouldRepaint(SplashScenePainter oldDelegate) =>
      t != oldDelegate.t ||
      breath != oldDelegate.breath ||
      logoRect != oldDelegate.logoRect ||
      colors.primary != oldDelegate.colors.primary ||
      colors.primaryGlow != oldDelegate.colors.primaryGlow ||
      colors.background != oldDelegate.colors.background;
}
