import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/splash/presentation/controller/splash_controller.dart';
import 'package:click_seguro_app/modules/splash/presentation/controller/splash_destination.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
      backgroundColor: context.colors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.shield,
              color: context.colors.textPrimaryForeground,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.appTitle.tr(),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: context.colors.textPrimaryForeground,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              AppStrings.splashTagline.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.textPrimaryForeground.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
