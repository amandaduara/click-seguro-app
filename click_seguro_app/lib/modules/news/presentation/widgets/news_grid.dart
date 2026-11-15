import 'package:click_seguro_app/core/theme/app_spacing.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:flutter/material.dart';

/// Grade de 2 colunas com capas de alturas variadas, estilo Pinterest
/// (FR-025 de specs/024-redesign-visual), como sliver: só os cartões
/// visíveis são montados, então "carregar mais" não remonta a lista toda.
///
/// A ordem da API segue da esquerda para a direita e de cima para baixo:
/// pares à esquerda, ímpares à direita. Com a letra muito grande (escala
/// total acima de 1,3), vira uma coluna, para o título não ficar espremido.
class NewsGrid extends StatelessWidget {
  const NewsGrid({super.key, required this.items, required this.itemBuilder});

  final List<NewsItemEntity> items;
  final Widget Function(NewsItemEntity item, double coverHeight) itemBuilder;

  /// Alturas que se repetem: a mesma lista dá sempre as mesmas capas.
  static const List<double> coverHeights = [150, 120, 175, 135];

  static const double singleColumnScale = 1.3;

  /// Capa mais alta na coluna única, que é mais larga.
  static const double singleColumnExtra = 40;

  /// Espaço entre as duas colunas.
  static const double columnGap = 14;

  static double coverHeightAt(int index) =>
      coverHeights[index % coverHeights.length];

  static bool isSingleColumn(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(10) / 10 > singleColumnScale;

  @override
  Widget build(BuildContext context) {
    if (isSingleColumn(context)) {
      return SliverList.builder(
        itemCount: items.length,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s6),
          child: itemBuilder(
            items[index],
            coverHeightAt(index) + singleColumnExtra,
          ),
        ),
      );
    }
    // Coluna [parity]: os índices `parity`, `parity + 2`, ...
    Widget column(int parity) => SliverPadding(
      padding: EdgeInsetsDirectional.only(
        end: parity == 0 ? columnGap / 2 : 0,
        start: parity == 1 ? columnGap / 2 : 0,
      ),
      sliver: SliverList.builder(
        itemCount: (items.length - parity + 1) ~/ 2,
        itemBuilder: (_, row) {
          final int index = row * 2 + parity;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s5),
            child: itemBuilder(items[index], coverHeightAt(index)),
          );
        },
      ),
    );
    return SliverCrossAxisGroup(slivers: [column(0), column(1)]);
  }
}
