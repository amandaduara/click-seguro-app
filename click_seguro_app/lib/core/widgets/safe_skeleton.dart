import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Bloco de carregamento com um brilho que corre a cada 1,4 s, no formato do
/// conteúdo que vai chegar (FR-018). Decorativo para o leitor de tela: quem
/// anuncia o carregamento é o `SafeLoadingState`. Parado com reduzir
/// animações (FR-021).
class SafeSkeleton extends StatefulWidget {
  const SafeSkeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = const BorderRadius.all(Radius.circular(12)),
  });

  final double? width;
  final double height;
  final BorderRadius radius;

  @override
  State<SafeSkeleton> createState() => _SafeSkeletonState();
}

class _SafeSkeletonState extends State<SafeSkeleton>
    with SingleTickerProviderStateMixin {
  static const Duration _period = Duration(milliseconds: 1400);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final Color base = colors.surfaceStrong;
    final Color shine = Color.lerp(base, colors.card, 0.6)!;
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final double t = _controller.value * 2 - 1; // -1 → 1
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: widget.radius,
                gradient: LinearGradient(
                  begin: Alignment(t - 1, 0),
                  end: Alignment(t + 1, 0),
                  colors: [base, shine, base],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
