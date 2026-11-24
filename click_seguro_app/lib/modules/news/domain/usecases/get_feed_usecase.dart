import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_feed_entity.dart';
import 'package:click_seguro_app/modules/news/domain/repositories/news_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetFeedUseCase {
  GetFeedUseCase(this._repository);

  final NewsRepository _repository;

  Future<Either<Failure, NewsFeedEntity>> call() =>
      _repository.getFeedFirstPage();
}
