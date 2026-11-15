import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/core/widgets/press_scale.dart';
import 'package:flutter/material.dart';

enum SafeCardElevation { flat, sm }

/// SafeCard — cartão do redesign 2.0 (FR-004): branco, borda de 1 px, canto
/// 20 e a sombra única; `flat` é creme e sem sombra. É o padrão de todo
/// cartão do app (notícias, perfil, configurações, alertas): quem desenha a
/// própria caixa usa [SafeCard.decoration]. Tocável: encolhe para 98% (FR-020), sem movimento com reduzir
/// animações (FR-021), e é lido como botão (specs/022 FR-007).
class SafeCard extends StatelessWidget {
  const SafeCard({
    super.key,
    required this.child,
    this.elevation = SafeCardElevation.sm,
    this.padded = true,
    this.interactive = false,
    this.onTap,
  });

  final Widget child;
  final SafeCardElevation elevation;
  final bool padded;
  final bool interactive;
  final VoidCallback? onTap;

  /// A caixa do cartão: branca (creme se [flat]), borda, canto 20 e sombra.
  static BoxDecoration decoration(AppPalette colors, {bool flat = false}) =>
      BoxDecoration(
        color: flat ? colors.surface : colors.card,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: colors.border),
        boxShadow: flat ? null : colors.shadow,
      );

  @override
  Widget build(BuildContext context) {
    final Widget card = AnimatedContainer(
      duration: AppMotion.of(context).short,
      curve: AppMotion.standard,
      padding: padded ? const EdgeInsets.all(AppSpacing.s5) : EdgeInsets.zero,
      decoration: decoration(
        context.colors,
        flat: elevation == SafeCardElevation.flat,
      ),
      // Conteúdo sem margem (capa de notícia) respeita o canto.
      clipBehavior: padded ? Clip.none : Clip.antiAlias,
      child: child,
    );

    if (!interactive) return card;

    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      child: PressScale(
        enabled: onTap != null,
        pressedScale: 0.98,
        onTap: onTap,
        child: card,
      ),
    );
  }
}
