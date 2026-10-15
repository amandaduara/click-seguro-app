import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/modules/settings/presentation/widgets/settings_tile.dart';
import 'package:flutter/material.dart';

/// Linha das Configurações com uma chave à direita (alertas, alto contraste,
/// leitura automática). A linha inteira inverte o valor; [onChanged] nulo
/// deixa a chave parada.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final ValueChanged<bool>? change = onChanged;
    return SettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: change == null ? null : () => change(!value),
      trailing: Switch(
        value: value,
        activeThumbColor: colors.card,
        activeTrackColor: colors.success,
        onChanged: change,
      ),
    );
  }
}
