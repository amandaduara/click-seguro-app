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
    this.hint,
    this.actions = const [],
  });

  final AppIllustration illustration;
  final String message;

  /// Texto de apoio abaixo da mensagem, mais claro.
  final String? hint;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double art = constraints.hasBoundedHeight
            ? (constraints.maxHeight * .32).clamp(96, 180).toDouble()
            : 180;
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
                // Mesmo tamanho em todo estado vazio ou de erro do app
                // (validação da usuária, specs/024): o texto da tela, em
                // seminegrito, e a dica mais clara embaixo.
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.textForeground,
                    height: 1.4,
                  ),
                ),
                if (hint case final String text) ...[
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      color: context.colors.textMutedForeground,
                      height: 1.4,
                    ),
                  ),
                ],
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
