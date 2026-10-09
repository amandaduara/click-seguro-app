import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/api_client/api_failure_mapper.dart';
import 'package:click_seguro_app/modules/news/data/datasources/news_local_data_source.dart';
import 'package:click_seguro_app/modules/news/data/datasources/news_remote_data_source.dart';
import 'package:click_seguro_app/modules/news/data/models/news_detail_model.dart';
import 'package:click_seguro_app/modules/news/data/models/news_feed_model.dart';
import 'package:click_seguro_app/modules/news/data/models/news_list_model.dart';
import 'package:click_seguro_app/modules/news/domain/entities/like_result_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_category_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_detail_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_feed_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_filter.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reels_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/saved_news_result.dart';
import 'package:click_seguro_app/modules/news/domain/failures/news_failures.dart';
import 'package:click_seguro_app/modules/news/domain/repositories/news_repository.dart';
import 'package:fpdart/fpdart.dart';

class NewsRepositoryImpl implements NewsRepository {
  NewsRepositoryImpl(this._remote, this._local);

  /// Falhas em que a cópia guardada substitui o feed (CB-001). Sessão
  /// recusada não entra: o aviso da feature 005 cuida dela.
  static const Set<ApiErrorType> _offlineErrors = {
    ApiErrorType.connection,
    ApiErrorType.timeout,
    ApiErrorType.server,
  };

  /// Falhas em que a cópia do detalhe e das salvas é usada (specs/010). Sem
  /// `server`: erro do servidor não é falta de internet.
  static const Set<ApiErrorType> _noConnectionErrors = {
    ApiErrorType.connection,
    ApiErrorType.timeout,
  };

  static const Map<String, dynamic> _noReels = {'data': <Object>[]};

  static const String _newsNotFoundCode = 'NEWS_NOT_FOUND';

  final NewsRemoteDataSource _remote;
  final NewsLocalDataSource _local;

  @override
  Future<Either<Failure, NewsFeedEntity>> getFeedFirstPage() async {
    // Os dois pedidos saem juntos; os Reels nunca lançam (_reelsOrEmpty).
    final reelsRequest = _reelsOrEmpty();
    try {
      final feed = await _remote.getFeed(page: 1);
      final reels = await reelsRequest;
      final entity = NewsFeedModel.fromJson(feed, reels).toEntity();
      await _local.writeFeed(feed, reels);
      return Right(entity);
    } on ApiException catch (e) {
      return _fromCacheOr(e);
    }
  }

  @override
  Future<Either<Failure, NewsPageEntity>> getFeedPage(int page) =>
      _guard(() async {
        final feed = await _remote.getFeed(page: page);
        return NewsFeedModel.fromJson(feed, null, page: page).toPage();
      });

  @override
  Future<Either<Failure, NewsPageEntity>> getNews(
    NewsFilter filter,
    int page,
  ) => _guard(() async {
    final list = await _remote.getNews(
      page: page,
      category: filter.categorySlug,
      search: filter.hasSearch ? filter.normalizedSearch : null,
    );
    return list.toEntity();
  });

  @override
  Future<Either<Failure, List<NewsCategoryEntity>>> getCategories() =>
      _guard(() async {
        final categories = await _remote.getCategories();
        return [for (final category in categories) category.toEntity()];
      });

  @override
  Future<Either<Failure, ReelsPageEntity>> getReels({String? cursor}) =>
      _guard(() async {
        final page = await _remote.getReelsPage(cursor: cursor);
        return page.toEntity();
      });

  @override
  Future<Either<Failure, LikeResultEntity>> toggleLike(String newsId) =>
      _guardNews(() async {
        final result = await _remote.toggleLike(newsId);
        return result.toEntity();
      });

  @override
  Future<Either<Failure, bool>> toggleSave(String newsId) =>
      _guardNews(() => _remote.toggleSave(newsId));

  @override
  Future<Either<Failure, NewsDetailResult>> getNewsDetail(String id) =>
      _guardNews(() async {
        try {
          final json = await _remote.getNewsDetail(id);
          final detail = _parseDetail(json);
          await _local.writeDetail(json);
          return NewsDetailResult(detail: detail, isFromCache: false);
        } on ApiException catch (e) {
          final cached = _noConnectionErrors.contains(e.type)
              ? await _local.readDetail(id)
              : null;
          if (cached == null) rethrow;
          return NewsDetailResult(
            detail: _parseDetail(cached),
            isFromCache: true,
          );
        }
      });

  @override
  Future<Either<Failure, Unit>> markAsRead(String id) => _guard(() async {
    await _remote.markAsRead(id);
    return unit;
  });

  @override
  Future<Either<Failure, SavedNewsResult>> getSavedNews(int page) =>
      _guard(() async {
        try {
          final json = await _remote.getSavedNews(page: page);
          final result = SavedNewsResult(
            page: _parseSavedPage(json),
            isFromCache: false,
          );
          if (page == 1) await _local.writeSavedPage(json);
          return result;
        } on ApiException catch (e) {
          final cached = page == 1 && _noConnectionErrors.contains(e.type)
              ? await _local.readSavedPage()
              : null;
          if (cached == null) rethrow;
          return SavedNewsResult(
            page: _parseSavedPage(cached),
            isFromCache: true,
          );
        }
      });

  /// Resposta fora do formato vira [ApiErrorType.invalidResponse], como nos
  /// pedidos que o `ApiClient` já converte.
  NewsDetailEntity _parseDetail(Map<String, dynamic> json) =>
      _parseOrInvalid(() => NewsDetailModel.fromJson(json).toEntity());

  NewsPageEntity _parseSavedPage(Map<String, dynamic> json) =>
      _parseOrInvalid(() => NewsListModel.fromJson(json).toEntity());

  T _parseOrInvalid<T>(T Function() parser) {
    try {
      return parser();
    } on TypeError catch (e) {
      throw _invalidResponse(e);
    } on FormatException catch (e) {
      throw _invalidResponse(e);
    }
  }

  ApiException _invalidResponse(Object error) => ApiException(
    type: ApiErrorType.invalidResponse,
    message: 'Resposta em formato inesperado: $error',
  );

  /// Falha só nos Reels não derruba o feed: o carrossel fica oculto.
  Future<Map<String, dynamic>> _reelsOrEmpty() async {
    try {
      return await _remote.getReels();
    } on ApiException {
      return _noReels;
    }
  }

  Future<Either<Failure, NewsFeedEntity>> _fromCacheOr(
    ApiException error,
  ) async {
    if (_offlineErrors.contains(error.type)) {
      final cached = await _local.readFeed();
      if (cached != null) {
        return Right(
          NewsFeedModel.fromJson(
            cached.feedJson,
            cached.reelsJson,
          ).toEntity(isFromCache: true),
        );
      }
    }
    return Left(error.toFailure());
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on ApiException catch (e) {
      return Left(e.toFailure());
    }
  }

  /// Como [_guard], mas notícia removida vira [NewsNotFoundFailure].
  Future<Either<Failure, T>> _guardNews<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.errorCode == _newsNotFoundCode) {
        return const Left(NewsNotFoundFailure());
      }
      return Left(e.toFailure());
    }
  }
}
