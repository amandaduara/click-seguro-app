import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/news/domain/entities/like_result_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_category_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_detail_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_feed_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_filter.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reels_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/saved_news_result.dart';
import 'package:fpdart/fpdart.dart';

abstract class NewsRepository {
  /// Primeira carga sem filtro; sem internet (ou com o servidor fora), a
  /// cópia guardada, se houver.
  Future<Either<Failure, NewsFeedEntity>> getFeedFirstPage();

  /// Páginas seguintes de "Tudo recente" (página 2 em diante).
  Future<Either<Failure, NewsPageEntity>> getFeedPage(int page);

  /// Lista por categoria e/ou busca.
  Future<Either<Failure, NewsPageEntity>> getNews(NewsFilter filter, int page);

  /// Só as categorias ativas.
  Future<Either<Failure, List<NewsCategoryEntity>>> getCategories();

  /// Uma parte dos Reels; sem [cursor], a primeira.
  Future<Either<Failure, ReelsPageEntity>> getReels({String? cursor});

  /// Alterna a curtida; devolve o estado do servidor. Exige conta.
  Future<Either<Failure, LikeResultEntity>> toggleLike(String newsId);

  /// Alterna salvar; devolve se ficou salva. Exige conta.
  Future<Either<Failure, bool>> toggleSave(String newsId);

  /// Notícia completa. Sem internet (conexão/tempo esgotado), a cópia do
  /// aparelho, se houver; id removido → `NewsNotFoundFailure`.
  Future<Either<Failure, NewsDetailResult>> getNewsDetail(String id);

  /// Registra a leitura (idempotente). Exige conta.
  Future<Either<Failure, Unit>> markAsRead(String id);

  /// Uma página das notícias salvas; sem internet na página 1, a cópia.
  /// Exige conta.
  Future<Either<Failure, SavedNewsResult>> getSavedNews(int page);
}
