import 'package:click_seguro_app/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// `Hero` de um botão de curtir, salvar ou compartilhar, que voa da coluna
/// do Reel para o topo do detalhe. Sem [tag] ou com movimento reduzido, é só
/// o botão: nada se move.
class NewsActionHero extends StatelessWidget {
  const NewsActionHero({super.key, required this.tag, required this.child});

  final String? tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String? tag = this.tag;
    if (tag == null || AppMotion.of(context).reduced) return child;
    // No voo o botão sai da árvore da tela: o `Material` dá o fundo que o
    // `InkWell` dos botões precisa.
    return Hero(
      tag: tag,
      flightShuttleBuilder: _shuttle,
      child: Material(type: MaterialType.transparency, child: child),
    );
  }

  /// No voo, o botão do Reel (redondo) vira o do detalhe (o curtir é uma
  /// pílula com o número): os dois se cruzam, cada um encolhido para caber
  /// no quadro do voo. Desenhar só o do detalhe no tamanho do botão
  /// redondo estourava a linha do curtir.
  static Widget _shuttle(
    BuildContext context,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromContext,
    BuildContext toContext,
  ) {
    final Widget from = (fromContext.widget as Hero).child;
    final Widget to = (toContext.widget as Hero).child;
    // A animação vai de 0 (Reel) a 1 (detalhe) na ida e volta na saída.
    final bool push = direction == HeroFlightDirection.push;
    final Widget detail = push ? to : from;
    final Widget reel = push ? from : to;
    Widget fitted(Widget child) => FittedBox(child: child);
    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: ReverseAnimation(animation),
          child: fitted(reel),
        ),
        FadeTransition(opacity: animation, child: fitted(detail)),
      ],
    );
  }
}
