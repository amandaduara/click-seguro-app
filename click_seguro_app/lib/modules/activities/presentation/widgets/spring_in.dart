import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:flutter/widgets.dart';

/// Entra com uma mola leve (FR-020 de specs/024); direto com reduzir
/// animações.
class SpringIn extends StatelessWidget {
  const SpringIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppMotion motion = AppMotion.of(context);
    if (motion.reduced) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: motion.long,
      curve: AppMotion.emphasis,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
}
