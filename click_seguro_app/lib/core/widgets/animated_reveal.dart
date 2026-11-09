import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Mostra [child] crescendo e esmaecendo; com `null`, encolhe e some
/// (specs/022 FR-023). Durante a saída, mostra o último conteúdo recebido.
///
/// Diferente de um `AnimatedSwitcher`, há uma única cópia do conteúdo na
/// tela, então um campo com `FocusNode` pode entrar e sair sem conflito.
class AnimatedReveal extends StatefulWidget {
  const AnimatedReveal({super.key, required this.child});

  /// `null` esconde.
  final Widget? child;

  @override
  State<AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<AnimatedReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;
  Widget? _last;

  @override
  void initState() {
    super.initState();
    // Aqui, não num `late` preguiçoso: o valor inicial é o do primeiro
    // `child`, não o de quando o controlador for lido pela primeira vez.
    _controller = AnimationController(
      vsync: this,
      value: widget.child == null ? 0 : 1,
    )..addStatusListener((_) => setState(() {}));
    _curve = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.enter,
      reverseCurve: AppMotion.exit,
    );
  }

  @override
  void didUpdateWidget(AnimatedReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool shown = widget.child != null;
    if (shown == (oldWidget.child != null)) return;
    final Duration duration = AppMotion.of(context).medium;
    _controller
      ..duration = duration
      ..reverseDuration = duration;
    if (shown) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget? child = widget.child ?? _last;
    _last = child;
    if (child == null || _controller.isDismissed) {
      if (widget.child == null) _last = null;
      return const SizedBox.shrink();
    }
    return SizeTransition(
      sizeFactor: _curve,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: _curve, child: child),
    );
  }
}
