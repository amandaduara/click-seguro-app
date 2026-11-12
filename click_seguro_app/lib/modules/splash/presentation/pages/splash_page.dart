import 'dart:async';

import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/modules/splash/presentation/controller/splash_controller.dart';
import 'package:click_seguro_app/modules/splash/presentation/controller/splash_destination.dart';
import 'package:click_seguro_app/modules/splash/presentation/widgets/splash_animation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  /// Cena animada inteira (para teste).
  static const ValueKey<String> sceneKey = ValueKey('splash.scene');

  /// Espaço da marca dentro da cena (para teste).
  static const ValueKey<String> logoKey = SplashAnimation.logoKey;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final Completer<void> _animationDone = Completer<void>();
  bool _animationFinished = false;

  @override
  void initState() {
    super.initState();
    unawaited(_goWhenReady());
  }

  // Sai quando a animação E a validação terminaram: o que vier por último.
  Future<void> _goWhenReady() async {
    final SplashController controller = context.read<SplashController>();
    await Future.wait<void>([
      controller.resolveDestination(),
      _animationDone.future,
    ]);

    final SplashDestination? destination = controller.destination;
    if (destination != null && mounted) {
      context.go(destination.path);
    }
  }

  void _onAnimationCompleted() {
    if (!_animationDone.isCompleted) {
      _animationDone.complete();
    }
    setState(() => _animationFinished = true);
  }

  @override
  Widget build(BuildContext context) {
    // A marca respira se a animação acabou e o destino ainda não saiu.
    final bool breathing =
        _animationFinished &&
        context.watch<SplashController>().destination == null;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Semantics(
        container: true,
        excludeSemantics: true,
        label: '${AppStrings.appTitle.tr()}. ${AppStrings.splashTagline.tr()}',
        child: SplashAnimation(
          key: SplashPage.sceneKey,
          onCompleted: _onAnimationCompleted,
          breathing: breathing,
        ),
      ),
    );
  }
}
