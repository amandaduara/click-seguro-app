import 'package:click_seguro_app/core/illustrations/app_illustration.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/safe_illustration.dart';
import 'package:flutter/material.dart';

/// Moldura comum dos estados de erro e vazio do redesign 2.0 (FR-019):
/// ilustração, texto centralizado e as ações da tela. Rola em telas curtas
/// ou com a letra grande, e a ilustração encolhe quando falta altura.
class SafeStateLayout extends StatelessWidget {
  const SafeStateLayout({
    super.key,
    required this.illustration,
    required this.message,
    this.actions = const [],
  });

  final AppIllustration illustration;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double art = constraints.hasBoundedHeight
            ? (constraints.maxHeight * .32).clamp(96, 200).toDouble()
            : 200;
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s6,
              vertical: AppSpacing.s5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SafeIllustration(illustration, height: art),
                const SizedBox(height: AppSpacing.s5),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.title2.copyWith(
                    color: context.colors.textForeground,
                    height: 1.3,
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s6),
                  ...actions,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
