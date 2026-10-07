import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/repositories/news_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetFeedPageUseCase {
  GetFeedPageUseCase(this._repository);

  final NewsRepository _repository;

  Future<Either<Failure, NewsPageEntity>> call(int page) =>
      _repository.getFeedPage(page);
}
