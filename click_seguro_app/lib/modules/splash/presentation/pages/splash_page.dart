import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/app_logo.dart';
import 'package:click_seguro_app/modules/splash/presentation/controller/splash_controller.dart';
import 'package:click_seguro_app/modules/splash/presentation/controller/splash_destination.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    final SplashController controller = context.read<SplashController>();
    await controller.resolveDestination();

    final SplashDestination? destination = controller.destination;
    if (destination != null && mounted) {
      context.go(destination.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s6),
            child: _Entrance(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLogo(size: 112),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.appTitle.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: context.colors.secondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    AppStrings.splashTagline.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.textMutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Entrada do logo e do título: esmaece e cresce de 0,9 a 1 (specs/022
/// FR-018). Com o movimento reduzido, a duração é zero e aparece pronto.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: AppMotion.of(context).long,
    curve: AppMotion.enter,
    child: child,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.scale(scale: 0.9 + 0.1 * value, child: child),
    ),
  );
}
