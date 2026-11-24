import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_list_kind.dart';
import 'package:click_seguro_app/modules/news/domain/entities/user_news_list_result.dart';
import 'package:click_seguro_app/modules/news/domain/repositories/news_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetUserNewsListUseCase {
  GetUserNewsListUseCase(this._repository);

  final NewsRepository _repository;

  Future<Either<Failure, UserNewsListResult>> call(
    NewsListKind kind,
    int page,
  ) => _repository.getUserNewsList(kind, page);
}
