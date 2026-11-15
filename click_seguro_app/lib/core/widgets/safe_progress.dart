import 'dart:math' as math;

import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

enum SafeProgressTone { primary, success }

/// Enche de 0 até [value] em 400 ms ao aparecer (FR-020); com reduzir
/// animações, já mostra o valor (FR-021).
class _AnimatedValue extends StatelessWidget {
  const _AnimatedValue({required this.value, required this.builder});

  final double value;
  final Widget Function(BuildContext context, double value) builder;

  @override
  Widget build(BuildContext context) {
    final double target = value.clamp(0, 1).toDouble();
    if (AppMotion.of(context).reduced) return builder(context, target);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: AppMotion.of(context).long,
      curve: AppMotion.enter,
      builder: (context, current, _) => builder(context, current),
    );
  }
}

/// Barra de progresso de 10 de altura (cartão de módulo).
class SafeProgressBar extends StatelessWidget {
  const SafeProgressBar({
    super.key,
    required this.value,
    this.tone = SafeProgressTone.primary,
  });

  final double value;
  final SafeProgressTone tone;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final Color fill = tone == SafeProgressTone.success
        ? colors.success
        : colors.primary;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: AppSpacing.radiusFull,
        child: Container(
          height: 10,
          color: colors.surfaceStrong,
          alignment: Alignment.centerLeft,
          child: _AnimatedValue(
            value: value,
            builder: (context, current) => FractionallySizedBox(
              widthFactor: current,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: AppSpacing.radiusFull,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Anel de progresso com o rótulo no centro (painel de atividades).
class SafeProgressRing extends StatelessWidget {
  const SafeProgressRing({super.key, required this.value, required this.label});

  static const double size = 104;

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _AnimatedValue(
            value: value,
            builder: (context, current) => CustomPaint(
              size: const Size.square(size),
              painter: _RingPainter(
                value: current,
                track: colors.surfaceStrong,
                fill: colors.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: AppTypography.title2.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textForeground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.track,
    required this.fill,
  });

  final double value;
  final Color track;
  final Color fill;
  static const double _stroke = 11;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = (Offset.zero & size).deflate(_stroke / 2);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = track);
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * value,
        false,
        paint..color = fill,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.track != track || old.fill != fill;
}

/// Um segmento por pergunta: respondidas em coral, a atual em coral claro e
/// as próximas em creme (pergunta da lição). [completed] diz, na ordem, quais
/// já foram respondidas.
class SafeSegmentedProgress extends StatelessWidget {
  const SafeSegmentedProgress({
    super.key,
    required this.completed,
    this.current,
  });

  final List<bool> completed;
  final int? current;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return ExcludeSemantics(
      child: Row(
        children: [
          for (final (i, done) in completed.indexed) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: done
                      ? colors.primary
                      : i == current
                      ? colors.primary.withValues(alpha: 0.35)
                      : colors.surfaceStrong,
                  borderRadius: AppSpacing.radiusFull,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
