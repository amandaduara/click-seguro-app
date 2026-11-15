import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Conteúdo de uma folha inferior do redesign 2.0: alça no topo e
/// espaçamento padrão. O canto de 32 e o fundo vêm do `bottomSheetTheme`.
class SafeSheet extends StatelessWidget {
  const SafeSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s6,
          AppSpacing.s3,
          AppSpacing.s6,
          AppSpacing.s6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: AppSpacing.radiusFull,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            child,
          ],
        ),
      ),
    );
  }
}
