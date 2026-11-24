import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Afunda o [child] ao toque (specs/022 FR-020). Mesmo num toque curto, o
/// afundamento vai até o fim, durando pelo menos `AppMotion.short`, e só
/// então volta; segurando, fica afundado até soltar.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.enabled,
    required this.pressedScale,
    required this.onTap,
    required this.child,
  });

  final bool enabled;
  final double pressedScale;
  final VoidCallback? onTap;
  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(vsync: this);
  late final Animation<double> _scale = _press.drive(
    Tween<double>(
      begin: 1,
      end: widget.pressedScale,
    ).chain(CurveTween(curve: AppMotion.standard)),
  );
  bool _held = false;

  void _down() {
    _held = true;
    _press.duration = AppMotion.of(context).short;
    _press.forward().then((_) {
      if (!_held && mounted) _release();
    });
  }

  void _up() {
    _held = false;
    if (_press.isCompleted) _release();
  }

  void _release() {
    _press.reverseDuration = AppMotion.of(context).short;
    _press.reverse();
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.enabled;
    return GestureDetector(
      onTapDown: enabled ? (_) => _down() : null,
      onTapUp: enabled ? (_) => _up() : null,
      onTapCancel: enabled ? _up : null,
      onTap: enabled ? widget.onTap : null,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
