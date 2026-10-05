import 'package:click_seguro_app/modules/news/data/models/news_category_model.dart';
import 'package:click_seguro_app/modules/news/data/models/news_list_model.dart';

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
}
