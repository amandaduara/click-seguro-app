import 'package:click_seguro_app/core/i18n/app_strings.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:easy_localization/easy_localization.dart';

/// Regras de exibição do cartão de notícia (research R7 de
/// specs/006-feed-inicio).
extension NewsItemPresentation on NewsItemEntity {
  static const List<String> _monthKeys = [
    AppStrings.newsMonthShort1,
    AppStrings.newsMonthShort2,
    AppStrings.newsMonthShort3,
    AppStrings.newsMonthShort4,
    AppStrings.newsMonthShort5,
    AppStrings.newsMonthShort6,
    AppStrings.newsMonthShort7,
    AppStrings.newsMonthShort8,
    AppStrings.newsMonthShort9,
    AppStrings.newsMonthShort10,
    AppStrings.newsMonthShort11,
    AppStrings.newsMonthShort12,
  ];

  /// "Hoje", "Ontem", "Há N dias" (até 6) ou "12 de set.", por dia de
  /// calendário local da publicação original.
  String relativeDate(DateTime now) {
    final local = originalPublishedAt.toLocal();
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(local.year, local.month, local.day)).inDays;
    if (days <= 0) return AppStrings.newsDateToday.tr();
    if (days == 1) return AppStrings.newsDateYesterday.tr();
    if (days < 7) return AppStrings.newsDateDaysAgo.tr(args: ['$days']);
    return AppStrings.newsDateFormat.tr(
      namedArgs: {
        'day': '${local.day}',
        'month': _monthKeys[local.month - 1].tr(),
      },
    );
  }

  /// Até [max] nomes de categoria e "+N" para as demais (RF-012, RN-002).
  List<String> categoryLabels({int max = 2}) => [
    for (final category in categories.take(max)) category.name,
    if (categories.length > max) '+${categories.length - max}',
  ];

  /// O que o leitor de tela lê no cartão.
  String semanticLabel(DateTime now) => [
    title,
    source,
    relativeDate(now),
    ...categories.map((category) => category.name),
  ].join(', ');
}

extension NewsItemsPresentation on Iterable<NewsItemEntity> {
  /// Notícias distintas publicadas nas últimas 24 h (spec, Q1).
  int newCount(DateTime now) {
    final since = now.subtract(const Duration(hours: 24));
    final seen = <String>{};
    return where(
      (item) => seen.add(item.id) && item.originalPublishedAt.isAfter(since),
    ).length;
  }
}
