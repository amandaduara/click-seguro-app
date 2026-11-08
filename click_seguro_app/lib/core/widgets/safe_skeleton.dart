import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:click_seguro_app/core/theme/app_palette.dart';
import 'package:click_seguro_app/core/widgets/safe_state_switcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Esqueleto no formato do conteúdo (specs/022 R8, FR-011 a FR-014): a tela
/// passa os próprios widgets com dados de exemplo em [child].
///
/// Ligado, é lido como "Carregando" e não expõe o texto de exemplo; com o
/// movimento reduzido, fica estático. Desligar troca para o conteúdo com um
/// esmaecimento de [AppMotion.medium].
class SafeSkeleton extends StatelessWidget {
  const SafeSkeleton({super.key, required this.enabled, required this.child});

  static const Duration _shimmerCycle = Duration(milliseconds: 1500);

  // Chave que o Skeletonizer dá à cópia em esqueleto dentro da troca.
  static const ValueKey<String> _skeletonKey = ValueKey('skeletonizer');

  final bool enabled;
  final Widget child;

  /// Texto de exemplo com [words] palavras, para os dados de exemplo das
  /// telas: vira barras no esqueleto e nunca é lido.
  static String text(int words) =>
      List<String>.filled(words, BoneMock.words(1)).join(' ');

  // A cópia em esqueleto que sai não é lida: o texto de exemplo ficaria
  // exposto ao leitor de tela durante a troca.
  static Widget _fade(Widget child, Animation<double> animation) =>
      FadeTransition(
        key: ValueKey<Key?>(child.key),
        opacity: animation,
        child: child.key == _skeletonKey
            ? ExcludeSemantics(child: child)
            : child,
      );

  @override
  Widget build(BuildContext context) {
    final AppPalette colors = context.colors;
    final AppMotion motion = AppMotion.of(context);

    // Estrutura fixa: trocar os wrappers ao ligar e desligar perderia a
    // animação de troca. Desligado, não é contêiner, para não juntar os
    // textos do conteúdo num nó só.
    return Semantics(
      container: enabled,
      liveRegion: enabled,
      label: enabled ? AppStrings.commonLoading.tr() : null,
      child: ExcludeSemantics(
        excluding: enabled,
        child: Skeletonizer(
          enabled: enabled,
          enableSwitchAnimation: !motion.reduced,
          switchAnimationConfig: SwitchAnimationConfig(
            duration: motion.medium,
            switchInCurve: AppMotion.standard,
            switchOutCurve: AppMotion.standard,
            transitionBuilder: _fade,
            layoutBuilder: topAlignedSwitcherLayout,
          ),
          // Sem isso, caixas com tom (selo, chip) aparecem coloridas por
          // baixo das barras.
          containersColor: colors.card,
          effect: motion.reduced
              ? SolidColorEffect(color: colors.input)
              : ShimmerEffect(
                  baseColor: colors.input,
                  highlightColor: colors.card,
                  duration: _shimmerCycle,
                ),
          child: child,
        ),
      ),
    );
  }
}
