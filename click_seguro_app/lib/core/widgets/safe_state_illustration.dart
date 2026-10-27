import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Artwork vetorial decorativo usado pelos estados compartilhados.
///
/// O desenho não contém texto nem animação e acompanha a paleta do tema,
/// inclusive no modo de alto contraste.
class SafeStateIllustration extends StatelessWidget {
  const SafeStateIllustration({
    super.key,
    required this.isError,
    required this.icon,
    this.size = 112,
  });

  final bool isError;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final double dimension = size.clamp(64, 144);
    final Color accent = isError ? colors.destructive : colors.primary;

    return Semantics(
      excludeSemantics: true,
      child: SizedBox(
        width: dimension * 1.3,
        height: dimension,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(dimension * 1.3, dimension),
              painter: _SafeStatePainter(
                isError: isError,
                primary: colors.primary,
                muted: colors.textMutedForeground,
                accent: accent,
                border: colors.border,
                card: colors.card,
              ),
            ),
            Positioned(
              right: dimension * .13,
              top: dimension * .08,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border, width: 1.5),
                ),
                child: Padding(
                  padding: EdgeInsets.all(dimension * .075),
                  child: Icon(icon, size: dimension * .22, color: accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafeStatePainter extends CustomPainter {
  const _SafeStatePainter({
    required this.isError,
    required this.primary,
    required this.muted,
    required this.accent,
    required this.border,
    required this.card,
  });

  final bool isError;
  final Color primary;
  final Color muted;
  final Color accent;
  final Color border;
  final Color card;

  @override
  void paint(Canvas canvas, Size size) {
    final double u = size.height / 112;
    final Offset center = Offset(size.width * .49, size.height * .56);
    final Paint fill = Paint()..style = PaintingStyle.fill;
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Fundo arredondado e pontos de cor dão volume sem depender de raster.
    fill.color = primary.withValues(alpha: .08);
    canvas.drawCircle(center, 42 * u, fill);
    fill.color = accent.withValues(alpha: .12);
    canvas.drawCircle(Offset(size.width * .19, size.height * .76), 8 * u, fill);
    fill.color = primary.withValues(alpha: .18);
    canvas.drawCircle(Offset(size.width * .77, size.height * .77), 5 * u, fill);

    final Rect sheet = Rect.fromCenter(
      center: Offset(center.dx, center.dy + 1 * u),
      width: 52 * u,
      height: 66 * u,
    );
    final RRect sheetShape = RRect.fromRectAndRadius(
      sheet,
      Radius.circular(9 * u),
    );
    fill.color = card;
    canvas.drawRRect(sheetShape, fill);
    stroke.color = border;
    canvas.drawRRect(sheetShape, stroke);

    if (isError) {
      // Folha com linhas interrompidas sugere uma requisição que falhou.
      stroke.color = muted.withValues(alpha: .62);
      for (final double y in [center.dy - 14 * u, center.dy - 4 * u]) {
        canvas.drawLine(
          Offset(center.dx - 13 * u, y),
          Offset(center.dx + 13 * u, y),
          stroke,
        );
      }
      canvas.drawLine(
        Offset(center.dx - 13 * u, center.dy + 7 * u),
        Offset(center.dx + 4 * u, center.dy + 7 * u),
        stroke,
      );
      stroke.color = accent;
      canvas.drawLine(
        Offset(center.dx + 10 * u, center.dy + 15 * u),
        Offset(center.dx + 24 * u, center.dy + 29 * u),
        stroke,
      );
      canvas.drawLine(
        Offset(center.dx + 24 * u, center.dy + 15 * u),
        Offset(center.dx + 10 * u, center.dy + 29 * u),
        stroke,
      );
    } else {
      // Caixa aberta representa um espaço ainda sem conteúdo.
      stroke.color = primary;
      final Path box = Path()
        ..moveTo(center.dx - 17 * u, center.dy - 7 * u)
        ..lineTo(center.dx, center.dy + 4 * u)
        ..lineTo(center.dx + 17 * u, center.dy - 7 * u)
        ..moveTo(center.dx - 17 * u, center.dy - 7 * u)
        ..lineTo(center.dx - 17 * u, center.dy + 15 * u)
        ..lineTo(center.dx, center.dy + 26 * u)
        ..lineTo(center.dx + 17 * u, center.dy + 15 * u)
        ..lineTo(center.dx + 17 * u, center.dy - 7 * u)
        ..moveTo(center.dx, center.dy + 4 * u)
        ..lineTo(center.dx, center.dy + 26 * u);
      canvas.drawPath(box, stroke);
      stroke.color = muted.withValues(alpha: .55);
      canvas.drawLine(
        Offset(center.dx - 12 * u, center.dy - 20 * u),
        Offset(center.dx + 12 * u, center.dy - 20 * u),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_SafeStatePainter oldDelegate) =>
      isError != oldDelegate.isError ||
      primary != oldDelegate.primary ||
      muted != oldDelegate.muted ||
      accent != oldDelegate.accent ||
      border != oldDelegate.border ||
      card != oldDelegate.card;
}
