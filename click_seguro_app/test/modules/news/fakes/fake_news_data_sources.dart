import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/news/data/datasources/news_local_data_source.dart';
import 'package:click_seguro_app/modules/news/data/datasources/news_remote_data_source.dart';
import 'package:click_seguro_app/modules/news/data/models/like_result_model.dart';
import 'package:click_seguro_app/modules/news/data/models/news_category_model.dart';
import 'package:click_seguro_app/modules/news/data/models/news_list_model.dart';
import 'package:click_seguro_app/modules/news/data/models/reels_page_model.dart';

import 'news_fixtures.dart';

/// Datasource remoto com respostas e erros configuráveis por método.
class FakeNewsRemoteDataSource implements NewsRemoteDataSource {
  Map<String, dynamic> feed = feedJson(recent: newsItemsJson(2));
  Map<String, dynamic> reels = reelsJson(items: [reelItemJson(id: 'reel1')]);
  Map<String, dynamic> list = newsListJson(items: newsItemsJson(1));
  List<Map<String, dynamic>> categories = categoriesJson;

  ApiException? feedError;
  ApiException? reelsError;
  ApiException? listError;
  ApiException? categoriesError;

  final List<int> feedPages = [];

  /// Partes da tela de Reels por cursor (`null` = primeira).
  final Map<String?, Map<String, dynamic>> reelsPages = {};
  Map<String, dynamic> likeResult = likeJson();
  bool saveResult = true;
  ApiException? likeError;
  ApiException? saveError;
  final List<String?> reelsCursors = [];
  final List<String> likeCalls = [];
  final List<String> saveCalls = [];
  final List<({int page, String? category, String? search})> listCalls = [];

  @override
  Future<Map<String, dynamic>> getFeed({required int page}) async {
    feedPages.add(page);
    if (feedError case final error?) throw error;
    return feed;
  }

  @override
  Future<Map<String, dynamic>> getReels() async {
    if (reelsError case final error?) throw error;
    return reels;
  }

  @override
  Future<NewsListModel> getNews({
    required int page,
    String? category,
    String? search,
  }) async {
    listCalls.add((page: page, category: category, search: search));
    if (listError case final error?) throw error;
    return NewsListModel.fromJson(list);
  }

  @override
  Future<List<NewsCategoryModel>> getCategories() async {
    if (categoriesError case final error?) throw error;
    return categories
        .map(NewsCategoryModel.fromJson)
        .where((c) => c.isActive)
        .toList();
  }

  @override
  Future<ReelsPageModel> getReelsPage({String? cursor}) async {
    reelsCursors.add(cursor);
    if (reelsError case final error?) throw error;
    return ReelsPageModel.fromJson(reelsPages[cursor] ?? reelsJson());
  }

  @override
  Future<LikeResultModel> toggleLike(String id) async {
    likeCalls.add(id);
    if (likeError case final error?) throw error;
    return LikeResultModel.fromJson(likeResult);
  }

  @override
  Future<bool> toggleSave(String id) async {
    saveCalls.add(id);
    if (saveError case final error?) throw error;
    return saveResult;
  }
}

/// Cópia guardada em memória.
class FakeNewsLocalDataSource implements NewsLocalDataSource {
  CachedFeed? cached;
  int writes = 0;

  @override
  Future<CachedFeed?> readFeed() async => cached;

  @override
  Future<void> writeFeed(
    Map<String, dynamic> feedJson,
    Map<String, dynamic> reelsJson,
  ) async {
    writes++;
    cached = CachedFeed(
      feedJson: feedJson,
      reelsJson: reelsJson,
      savedAt: DateTime.utc(2026, 10, 5, 12),
    );
  }
}

ApiException apiError(ApiErrorType type) =>
    ApiException(type: type, message: 'erro de teste');
