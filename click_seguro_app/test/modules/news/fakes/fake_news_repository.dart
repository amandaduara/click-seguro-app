import 'dart:async';

import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/news/domain/entities/like_result_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_category_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_detail_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_feed_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_filter.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_item_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reel_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reels_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/saved_news_result.dart';
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

/// Reel de teste (`sourceUrl` padrão `https://fonte.test/<id>`).
ReelEntity reel(
  String id, {
  int likesCount = 3,
  bool isSaved = false,
  bool isLiked = false,
  String? sourceUrl,
  String content = 'Texto do reel',
  String? imageUrl,
}) {
  final base = newsItem(id, imageUrl: imageUrl);
  return ReelEntity(
    news: NewsItemEntity(
      id: base.id,
      title: base.title,
      source: base.source,
      sourceUrl: sourceUrl ?? base.sourceUrl,
      imageUrl: base.imageUrl,
      originalPublishedAt: base.originalPublishedAt,
      categories: base.categories,
    ),
    content: content,
    likesCount: likesCount,
    isSaved: isSaved,
    isLiked: isLiked,
  );
}

List<ReelEntity> reels(int count, {int start = 1}) => [
  for (var i = start; i < start + count; i++) reel('r$i'),
];

/// Detalhe de teste (`sourceUrl` padrão `https://fonte.test/n`).
NewsDetailEntity newsDetail(
  String id, {
  String content = 'Texto',
  bool isSaved = false,
  SuggestedModuleEntity? suggestedModule,
  String sourceUrl = 'https://fonte.test/n',
  int likesCount = 2,
  String? imageUrl,
}) {
  final base = newsItem(id, interaction: NewsInteraction(isSaved: isSaved));
  return NewsDetailEntity(
    news: NewsItemEntity(
      id: base.id,
      title: base.title,
      source: base.source,
      sourceUrl: sourceUrl,
      imageUrl: imageUrl,
      originalPublishedAt: base.originalPublishedAt,
      categories: base.categories,
      interaction: base.interaction,
    ),
    content: content,
    likesCount: likesCount,
    readsCount: 1,
    suggestedModule: suggestedModule,
  );
}

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

  /// Partes dos Reels por cursor (`null` = primeira). Sem entrada → parte
  /// vazia, fim.
  final Map<String?, Either<Failure, ReelsPageEntity>> reelsResults = {};

  /// Respostas usadas antes do [reelsResults], uma por pedido.
  final List<Either<Failure, ReelsPageEntity>> reelsQueue = [];

  /// Filas de respostas; vazias → sucesso padrão.
  final List<Either<Failure, LikeResultEntity>> likeResults = [];
  final List<Either<Failure, bool>> saveResults = [];

  /// Filas de respostas do detalhe, da leitura e das salvas (specs/010);
  /// vazias → sucesso padrão.
  final List<Either<Failure, NewsDetailResult>> detailResults = [];
  final List<Either<Failure, Unit>> readResults = [];
  final List<Either<Failure, SavedNewsResult>> savedResults = [];

  Completer<void>? detailGate;
  Completer<void>? savedGate;
  Completer<void>? readGate;
  final List<String> detailCalls = [];
  final List<String> readCalls = [];
  final List<int> savedCalls = [];

  Completer<void>? reelsGate;
  Completer<void>? likeGate;
  Completer<void>? saveGate;
  final List<String?> reelsCalls = [];
  final List<String> likeCalls = [];
  final List<String> saveCalls = [];

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

  @override
  Future<Either<Failure, ReelsPageEntity>> getReels({String? cursor}) async {
    reelsCalls.add(cursor);
    final result = reelsQueue.isNotEmpty
        ? reelsQueue.removeAt(0)
        : reelsResults[cursor] ??
              const Right(ReelsPageEntity(items: [], nextCursor: null));
    await reelsGate?.future;
    return result;
  }

  @override
  Future<Either<Failure, LikeResultEntity>> toggleLike(String newsId) async {
    likeCalls.add(newsId);
    final result = likeResults.isEmpty
        ? const Right<Failure, LikeResultEntity>(
            LikeResultEntity(liked: true, likesCount: 4),
          )
        : _next(likeResults);
    await likeGate?.future;
    return result;
  }

  @override
  Future<Either<Failure, bool>> toggleSave(String newsId) async {
    saveCalls.add(newsId);
    final result = saveResults.isEmpty
        ? const Right<Failure, bool>(true)
        : _next(saveResults);
    await saveGate?.future;
    return result;
  }

  @override
  Future<Either<Failure, NewsDetailResult>> getNewsDetail(String id) async {
    detailCalls.add(id);
    final result = detailResults.isEmpty
        ? Right<Failure, NewsDetailResult>(
            NewsDetailResult(detail: newsDetail(id), isFromCache: false),
          )
        : _next(detailResults);
    await detailGate?.future;
    return result;
  }

  @override
  Future<Either<Failure, Unit>> markAsRead(String id) async {
    readCalls.add(id);
    final result = readResults.isEmpty
        ? const Right<Failure, Unit>(unit)
        : _next(readResults);
    await readGate?.future;
    return result;
  }

  @override
  Future<Either<Failure, SavedNewsResult>> getSavedNews(int page) async {
    savedCalls.add(page);
    final result = savedResults.isEmpty
        ? Right<Failure, SavedNewsResult>(
            SavedNewsResult(
              page: NewsPageEntity(items: const [], hasMore: false, page: page),
              isFromCache: false,
            ),
          )
        : _next(savedResults);
    await savedGate?.future;
    return result;
  }
}
