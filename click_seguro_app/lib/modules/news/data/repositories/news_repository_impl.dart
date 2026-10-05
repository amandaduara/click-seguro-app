import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/api_client/api_failure_mapper.dart';
import 'package:click_seguro_app/modules/news/data/datasources/news_local_data_source.dart';
import 'package:click_seguro_app/modules/news/data/datasources/news_remote_data_source.dart';
import 'package:click_seguro_app/modules/news/data/models/news_feed_model.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_category_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_feed_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_filter.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';
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

  static const Map<String, dynamic> _noReels = {'data': <Object>[]};

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
}
