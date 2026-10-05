import 'dart:async';

import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_category_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_feed_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_filter.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/repositories/news_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Notícia de teste.
NewsItemEntity newsItem(
  String id, {
  DateTime? originalPublishedAt,
  List<NewsCategoryEntity> categories = const [
    NewsCategoryEntity(id: 'c-phishing', name: 'Phishing', slug: 'phishing'),
  ],
  String? imageUrl,
  NewsInteraction interaction = const NewsInteraction(),
}) => NewsItemEntity(
  id: id,
  title: 'Notícia $id',
  source: 'Folha de Teste',
  sourceUrl: 'https://fonte.test/$id',
  imageUrl: imageUrl,
  originalPublishedAt: originalPublishedAt ?? DateTime(2026, 9, 20),
  categories: categories,
  interaction: interaction,
);

List<NewsItemEntity> newsItems(int count, {int start = 1}) => [
  for (var i = start; i < start + count; i++) newsItem('n$i'),
];

NewsFeedEntity newsFeed({
  List<NewsItemEntity> highlights = const [],
  List<NewsItemEntity> recommended = const [],
  List<NewsItemEntity>? recent,
  bool hasMore = false,
  List<NewsItemEntity> reels = const [],
  bool isFromCache = false,
}) => NewsFeedEntity(
  highlights: highlights,
  recommended: recommended,
  recent: NewsPageEntity(
    items: recent ?? newsItems(2),
    hasMore: hasMore,
    page: 1,
  ),
  reels: reels,
  isFromCache: isFromCache,
);

/// Repository em memória: cada método tem uma fila de respostas (a última se
/// repete) e um `Completer` opcional para segurar a resposta.
class FakeNewsRepository implements NewsRepository {
  final List<Either<Failure, NewsFeedEntity>> feedResults = [Right(newsFeed())];
  final Map<int, Either<Failure, NewsPageEntity>> feedPages = {};
  final List<Either<Failure, NewsPageEntity>> newsResults = [
    Right(NewsPageEntity(items: newsItems(1), hasMore: false, page: 1)),
  ];
  Either<Failure, List<NewsCategoryEntity>> categoriesResult = const Right([
    NewsCategoryEntity(id: 'c-phishing', name: 'Phishing', slug: 'phishing'),
    NewsCategoryEntity(
      id: 'c-bank',
      name: 'Golpes bancários',
      slug: 'golpes-bancarios',
    ),
  ]);

  Completer<void>? feedGate;
  Completer<void>? newsGate;

  int feedCalls = 0;
  int categoriesCalls = 0;
  final List<int> feedPageCalls = [];
  final List<({NewsFilter filter, int page})> newsCalls = [];

  T _next<T>(List<T> queue) =>
      queue.length > 1 ? queue.removeAt(0) : queue.first;

  @override
  Future<Either<Failure, NewsFeedEntity>> getFeedFirstPage() async {
    feedCalls++;
    final result = _next(feedResults);
    await feedGate?.future;
    return result;
  }

  @override
  Future<Either<Failure, NewsPageEntity>> getFeedPage(int page) async {
    feedPageCalls.add(page);
    return feedPages[page] ??
        Right(NewsPageEntity(items: const [], hasMore: false, page: page));
  }

  @override
  Future<Either<Failure, NewsPageEntity>> getNews(
    NewsFilter filter,
    int page,
  ) async {
    newsCalls.add((filter: filter, page: page));
    final result = _next(newsResults);
    await newsGate?.future;
    return result;
  }

  @override
  Future<Either<Failure, List<NewsCategoryEntity>>> getCategories() async {
    categoriesCalls++;
    return categoriesResult;
  }
}
