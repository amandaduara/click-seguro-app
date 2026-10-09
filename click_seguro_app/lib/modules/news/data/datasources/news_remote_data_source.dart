import 'package:click_seguro_app/modules/news/data/models/like_result_model.dart';
import 'package:click_seguro_app/modules/news/data/models/news_category_model.dart';
import 'package:click_seguro_app/modules/news/data/models/news_list_model.dart';
import 'package:click_seguro_app/modules/news/data/models/reels_page_model.dart';

/// Pedidos de notícias ao servidor. Erros sobem como `ApiException`.
abstract class NewsRemoteDataSource {
  /// Resposta crua de `/app/news/feed` (guardada como cópia na 1ª página).
  Future<Map<String, dynamic>> getFeed({required int page});

  /// Resposta crua dos primeiros Reels (carrossel).
  Future<Map<String, dynamic>> getReels();

  /// Lista por categoria e/ou busca. Começar uma consulta cancela a anterior.
  Future<NewsListModel> getNews({
    required int page,
    String? category,
    String? search,
  });

  /// Só as categorias ativas.
  Future<List<NewsCategoryModel>> getCategories();

  /// Uma parte da tela de Reels; sem [cursor], a primeira.
  Future<ReelsPageModel> getReelsPage({String? cursor});

  /// `POST /app/news/{id}/like` (alterna).
  Future<LikeResultModel> toggleLike(String id);

  /// `POST /app/news/{id}/save` (alterna); devolve se ficou salva.
  Future<bool> toggleSave(String id);

  /// Resposta crua de `GET /app/news/{id}` (guardada como cópia).
  Future<Map<String, dynamic>> getNewsDetail(String id);

  /// `POST /app/news/{id}/read` (204, idempotente).
  Future<void> markAsRead(String id);

  /// Resposta crua de `GET /users/me/news/saved` (a página 1 vira cópia).
  Future<Map<String, dynamic>> getSavedNews({required int page});
}
