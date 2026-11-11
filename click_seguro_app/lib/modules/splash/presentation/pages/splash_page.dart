import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/app_logo.dart';
import 'package:click_seguro_app/modules/splash/presentation/controller/splash_controller.dart';
import 'package:click_seguro_app/modules/splash/presentation/controller/splash_destination.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
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
    final AppPalette colors = context.colors;
    // Redesign 2.0 (Figma, quadro 01): fundo creme e a logo oficial num
    // círculo branco.
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s6),
            child: _Entrance(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 168,
                    height: 168,
                    decoration: BoxDecoration(
                      color: colors.card,
                      shape: BoxShape.circle,
                      boxShadow: colors.shadow,
                      border: colors.shadow.isEmpty
                          ? Border.all(color: colors.border)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: const AppLogo(size: 96),
                  ),
                  const SizedBox(height: AppSpacing.s7),
                  Text(
                    AppStrings.appTitle.tr(),
                    textAlign: TextAlign.center,
                    style: AppTypography.display.copyWith(
                      fontSize: 32,
                      color: colors.textForeground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    AppStrings.splashTagline.tr(),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge.copyWith(
                      color: colors.textBody,
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
