import 'dart:async';

import 'package:animations/animations.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// Container das abas do shell (specs/022 FR-016): mantém todas montadas,
/// com a pilha e a rolagem de cada uma, pausa as animações das escondidas e
/// esmaece só a que entra, em [AppMotion.medium].
class TabBranchContainer extends StatefulWidget {
  const TabBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<TabBranchContainer> createState() => _TabBranchContainerState();
}

class _TabBranchContainerState extends State<TabBranchContainer>
    with SingleTickerProviderStateMixin {
  // Começa completa: a primeira aba aparece sem animar.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    value: 1,
  );

  @override
  void didUpdateWidget(TabBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex == widget.currentIndex) return;
    final Duration duration = AppMotion.of(context).medium;
    if (duration == Duration.zero) {
      _entrance.value = 1;
    } else {
      _entrance.duration = duration;
      unawaited(_entrance.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      for (final (int index, Widget child) in widget.children.indexed)
        _Branch(
          active: index == widget.currentIndex,
          animation: index == widget.currentIndex
              ? _entrance
              : kAlwaysCompleteAnimation,
          child: child,
        ),
    ],
  );
}

class _Branch extends StatelessWidget {
  const _Branch({
    required this.active,
    required this.animation,
    required this.child,
  });

  final bool active;
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => Offstage(
    offstage: !active,
    child: TickerMode(
      enabled: active,
      child: FadeThroughTransition(
        animation: animation,
        secondaryAnimation: kAlwaysDismissedAnimation,
        fillColor: Colors.transparent,
        child: child,
      ),
    ),
  );
}
