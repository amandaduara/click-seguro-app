import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Título de seção e as linhas dela num cartão branco (quadro
/// "Configurações").
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s1,
            AppSpacing.s5,
            AppSpacing.s1,
            AppSpacing.s2,
          ),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.secondary,
              ),
            ),
          ),
        ),
        Material(
          color: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.radius2xl,
            side: BorderSide(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (index, child) in children.indexed) ...[
                if (index > 0)
                  Divider(height: 1, thickness: 1, color: colors.border),
                child,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
