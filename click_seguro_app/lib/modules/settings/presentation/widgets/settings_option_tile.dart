import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter/material.dart';

/// Linha de escolha única no visual do [SettingsTile], com o botão de opção à
/// direita. Fica dentro de um [RadioGroup] de [T], que diz qual está marcada e
/// recebe a escolha; a linha inteira é tocável (R3 de specs/014).
class SettingsOptionTile<T> extends StatelessWidget {
  const SettingsOptionTile({
    super.key,
    required this.value,
    required this.title,
    this.trailingText,
  });

  final T value;
  final String title;

  /// Texto à direita, antes do botão (ex.: "115%").
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? detail = trailingText;
    return MergeSemantics(
      child: InkWell(
        onTap: () => RadioGroup.maybeOf<T>(context)?.onChanged(value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: SettingsTile.minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textForeground,
                    ),
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(width: AppSpacing.s2),
                  Text(
                    detail,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: colors.textMutedForeground,
                    ),
                  ),
                ],
                const SizedBox(width: AppSpacing.s2),
                Radio<T>(value: value, activeColor: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
