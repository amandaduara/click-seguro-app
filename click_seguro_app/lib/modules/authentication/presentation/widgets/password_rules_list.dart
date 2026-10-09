import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Regras da senha com check nas atendidas (FR-005). Recebe os textos já
/// traduzidos, na ordem de exibição, e se cada um foi atendido.
class PasswordRulesList extends StatelessWidget {
  const PasswordRulesList({super.key, required this.rules});

  final List<({String label, bool met})> rules;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rule in rules)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s1),
            child: MergeSemantics(
              child: Row(
                children: [
                  Icon(
                    rule.met
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: rule.met
                        ? context.colors.success
                        : context.colors.textMutedForeground,
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Expanded(
                    child: Text(
                      rule.label,
                      style: textStyle?.copyWith(
                        color: rule.met
                            ? context.colors.textForeground
                            : context.colors.textMutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
