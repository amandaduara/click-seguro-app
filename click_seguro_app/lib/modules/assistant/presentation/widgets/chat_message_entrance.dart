import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Mensagem nova do chat entrando: sobe um pouco e esmaece para dentro
/// (specs/022 FR-026). Não cresce: a altura final já vale no primeiro quadro,
/// e a rolagem até o fim do chat chega mesmo ao fim. Com [animate] falso (as
/// que já estavam na tela) aparece direto.
class ChatMessageEntrance extends StatefulWidget {
  const ChatMessageEntrance({
    super.key,
    required this.animate,
    required this.child,
  });

  final bool animate;
  final Widget child;

  @override
  State<ChatMessageEntrance> createState() => _ChatMessageEntranceState();
}

class _ChatMessageEntranceState extends State<ChatMessageEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      value: widget.animate ? 0 : 1,
    );
    _curve = CurvedAnimation(parent: _controller, curve: AppMotion.enter);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      _controller
        ..duration = AppMotion.of(context).medium
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _curve,
    child: SlideTransition(
      position: _curve.drive(
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero),
      ),
      child: widget.child,
    ),
  );
}
