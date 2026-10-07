import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_category_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_feed_entity.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_filter.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';
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
}
