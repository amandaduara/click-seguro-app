import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/theme/app_typography.dart';
import 'package:click_seguro_app/core/widgets/safe_card.dart';
import 'package:flutter/material.dart';

/// Título discreto de seção e as linhas dela num cartão padrão (SafeCard).
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

/// Título de uma seção das Configurações: discreto (cinza), acima do cartão.
/// Separado do [SettingsCard] para a tela de Acessibilidade pôr a prévia
/// entre os dois (specs/014).
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s1,
        AppSpacing.s7,
        AppSpacing.s1,
        AppSpacing.s3,
      ),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: AppTypography.body.fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: context.colors.textMutedForeground,
          ),
        ),
      ),
    );
  }
}

/// Cartão padrão (SafeCard) com as linhas separadas por divisórias finas,
/// recuadas das bordas.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    // A caixa padrão dos cartões; o Material por dentro dá o efeito de toque
    // das linhas, recortado no canto.
    return DecoratedBox(
      decoration: SafeCard.decoration(colors),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: AppSpacing.radiusLg,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (final (index, child) in children.indexed) ...[
              if (index > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: AppSpacing.s4,
                  endIndent: AppSpacing.s4,
                  color: colors.border,
                ),
              child,
            ],
          ],
        ),
      ),
    );
  }
}
