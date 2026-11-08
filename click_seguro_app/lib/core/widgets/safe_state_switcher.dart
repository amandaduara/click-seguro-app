import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:flutter/widgets.dart';

/// Layout de `AnimatedSwitcher` alinhado no topo: se as alturas diferirem,
/// nada desliza nem fica centralizado.
Widget topAlignedSwitcherLayout(
  Widget? currentChild,
  List<Widget> previousChildren,
) => Stack(
  alignment: Alignment.topCenter,
  children: [...previousChildren, ?currentChild],
);

/// Troca animada entre carregando, conteúdo, vazio e erro (specs/022 R8):
/// esmaece em [AppMotion.medium] quando [stateKey] muda; com o movimento
/// reduzido, troca na hora.
class SafeStateSwitcher extends StatelessWidget {
  const SafeStateSwitcher({
    super.key,
    required this.stateKey,
    required this.child,
  });

  final Object stateKey;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: AppMotion.of(context).medium,
    switchInCurve: AppMotion.standard,
    switchOutCurve: AppMotion.standard,
    layoutBuilder: topAlignedSwitcherLayout,
    child: KeyedSubtree(key: ValueKey<Object>(stateKey), child: child),
  );
}
