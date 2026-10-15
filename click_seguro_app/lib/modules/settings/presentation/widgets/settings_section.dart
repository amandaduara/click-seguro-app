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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionTitle(title),
        SettingsCard(children: children),
      ],
    );
  }
}

/// Título de uma seção das Configurações. Separado do [SettingsCard] para a
/// tela de Acessibilidade pôr a prévia entre os dois (specs/014).
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            color: context.colors.secondary,
          ),
        ),
      ),
    );
  }
}

/// Cartão branco com borda e as linhas separadas por divisórias.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    return Material(
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
    );
  }
}
