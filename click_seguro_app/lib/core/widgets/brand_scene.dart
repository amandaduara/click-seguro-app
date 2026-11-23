import 'dart:math' as math;

import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/brand_mark.dart';
import 'package:flutter/material.dart';

/// Geometria do fim da splash que outras telas repetem (specs/026 R2): onde a
/// marca, o nome e o slogan ficam, e as duas ondas coral do rodapé. A splash
/// anima essas peças; o login começa exatamente onde elas param.
abstract final class BrandScene {
  // Larguras de referência do protótipo (390 px de largura, 164 px de marca).
  static const double referenceWidth = 390;
  static const double _maxLogoWidth = 164;
  static const double _minLogoWidth = 96;

  /// Altura da onda vermelha que fica no rodapé ao fim da abertura.
  static const double footerHeight = 110;

  /// Altura da onda de brilho, atrás da vermelha; a caixa da [BrandWave].
  static const double glowFooterHeight = 136;

  /// Espaço entre o nome e o slogan.
  static const double taglineGap = AppSpacing.s2;

  // Bordas das ondas (x, y de controle em 390 px; y a partir do topo da onda).
  static const List<double> frontEdge = [
    0, 52, 68, 14, 128, 18, 196, 54, 262, 90, 322, 104, 390, 84, //
  ];
  static const List<double> glowEdge = [
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
      math.max(viewportHeight * 0.28, topInset + AppSpacing.s6),
      logoWidth,
      logoHeight,
    );
  }

  /// Topo do nome do app, abaixo da marca em [logo]; o slogan vem
  /// [taglineGap] abaixo do nome.
  static double titleTopFor(Rect logo) => logo.bottom + AppSpacing.s7;

  /// Onda com borda [edge], cujo topo de repouso é [top], numa tela de
  /// [size]. Com [progress] 0 ela está acima da tela (cobre tudo); com 1,
  /// parada no rodapé. [below] é a área colorida (abaixo da borda); senão, a
  /// área acima dela.
  static Path wavePath(
    Size size, {
    required List<double> edge,
    required double top,
    required double progress,
    required bool below,
  }) {
    final double sx = size.width / referenceWidth;
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
}

/// As duas ondas paradas no rodapé, como no fim da splash. Decorativa.
class BrandWave extends StatelessWidget {
  const BrandWave({super.key});

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return ExcludeSemantics(
      child: SizedBox(
        width: double.infinity,
        height: BrandScene.glowFooterHeight,
        child: CustomPaint(
          painter: BrandWavePainter(
            front: colors.primary,
            glow: colors.primaryGlow,
          ),
        ),
      ),
    );
  }
}

/// Pinta as ondas de [BrandWave] numa caixa da altura da onda de brilho.
class BrandWavePainter extends CustomPainter {
  const BrandWavePainter({required this.front, required this.glow});

  final Color front;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..drawPath(
        BrandScene.wavePath(
          size,
          edge: BrandScene.glowEdge,
          top: size.height - BrandScene.glowFooterHeight,
          progress: 1,
          below: true,
        ),
        Paint()..color = glow,
      )
      ..drawPath(
        BrandScene.wavePath(
          size,
          edge: BrandScene.frontEdge,
          top: size.height - BrandScene.footerHeight,
          progress: 1,
          below: true,
        ),
        Paint()..color = front,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(BrandWavePainter oldDelegate) =>
      front != oldDelegate.front || glow != oldDelegate.glow;
}
