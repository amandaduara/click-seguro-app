import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:flutter/material.dart';

/// Grade de 2 colunas com capas de alturas variadas, estilo Pinterest
/// (FR-025 de specs/023-redesign-visual). A ordem da API segue da esquerda
/// para a direita e de cima para baixo: pares à esquerda, ímpares à
/// direita. Com a letra muito grande (escala total acima de 1,3), vira uma
/// coluna, para o título não ficar espremido.
class NewsGrid extends StatelessWidget {
  const NewsGrid({super.key, required this.items, required this.itemBuilder});

  final List<NewsItemEntity> items;
  final Widget Function(NewsItemEntity item, double coverHeight) itemBuilder;

  /// Alturas que se repetem: a mesma lista dá sempre as mesmas capas.
  static const List<double> coverHeights = [150, 120, 175, 135];

  static const double singleColumnScale = 1.3;

  static double coverHeightAt(int index) =>
      coverHeights[index % coverHeights.length];

  @override
  Widget build(BuildContext context) {
    final bool singleColumn =
        MediaQuery.textScalerOf(context).scale(10) / 10 > singleColumnScale;
    if (singleColumn) {
      return Column(
        children: [
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s6),
              child: itemBuilder(items[i], coverHeightAt(i) + 40),
            ),
        ],
      );
    }
    Widget column(int parity) => Expanded(
      child: Column(
        children: [
          for (int i = parity; i < items.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s5),
              child: itemBuilder(items[i], coverHeightAt(i)),
            ),
        ],
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [column(0), const SizedBox(width: 14), column(1)],
    );
  }
}
