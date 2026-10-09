import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/news/data/datasources/news_remote_data_source.dart';
import 'package:click_seguro_app/modules/news/data/models/like_result_model.dart';
import 'package:click_seguro_app/modules/news/data/models/news_category_model.dart';
import 'package:click_seguro_app/modules/news/data/models/news_feed_model.dart';
import 'package:click_seguro_app/modules/news/data/models/news_list_model.dart';
import 'package:click_seguro_app/modules/news/data/models/reels_page_model.dart';
import 'package:dio/dio.dart';

class NewsRemoteDataSourceImpl implements NewsRemoteDataSource {
  NewsRemoteDataSourceImpl(this._apiClient);

  static const String feedPath = '/app/news/feed';
  static const String reelsPath = '/app/news/reels';
  static const String newsPath = '/app/news';
  static const String categoriesPath = '/categories';

  /// Reels do carrossel "Novidades".
  static const int reelsPreviewLimit = 10;

  /// Reels por parte na tela de Reels (specs/008).
  static const int reelsPageSize = 10;

  final ApiClient _apiClient;

  /// Consulta de lista em andamento, cancelada quando outra começa (RNF-005).
  CancelToken? _listToken;

  // O cursor do feed é ignorado pelo servidor; a paginação é por página
  // (research R1 de specs/006-feed-inicio).
  @override
  Future<Map<String, dynamic>> getFeed({required int page}) async {
    final response = await _apiClient.get(
      feedPath,
      queryParameters: {'page': page, 'limit': NewsFeedModel.pageSize},
    );
    return response.toModel((json) => json);
  }

  @override
  Future<Map<String, dynamic>> getReels() async {
    final response = await _apiClient.get(
      reelsPath,
      queryParameters: {'limit': reelsPreviewLimit},
    );
    return response.toModel((json) => json);
  }

  @override
  Future<NewsListModel> getNews({
    required int page,
    String? category,
    String? search,
  }) async {
    _listToken?.cancel();
    final token = _listToken = CancelToken();
    final response = await _apiClient.get(
      newsPath,
      queryParameters: {
        'page': page,
        'limit': NewsFeedModel.pageSize,
        'category': ?category,
        'search': ?search,
        'sortBy': 'publishedAt',
        'sortOrder': 'desc',
      },
      cancelToken: token,
    );
    return response.toModel(NewsListModel.fromJson);
  }

  @override
  Future<List<NewsCategoryModel>> getCategories() async {
    final response = await _apiClient.get(categoriesPath);
    return response
        .toModelList(NewsCategoryModel.fromJson)
        .where((category) => category.isActive)
        .toList();
  }

  @override
  Future<ReelsPageModel> getReelsPage({String? cursor}) async {
    final response = await _apiClient.get(
      reelsPath,
      queryParameters: {'limit': reelsPageSize, 'cursor': ?cursor},
    );
    return response.toModel(ReelsPageModel.fromJson);
  }

  @override
  Future<LikeResultModel> toggleLike(String id) async {
    final response = await _apiClient.post('$newsPath/$id/like');
    return response.toModel(LikeResultModel.fromJson);
  }

  @override
  Future<bool> toggleSave(String id) async {
    final response = await _apiClient.post('$newsPath/$id/save');
    return response.toModel((json) => json['saved'] as bool);
  }
}
