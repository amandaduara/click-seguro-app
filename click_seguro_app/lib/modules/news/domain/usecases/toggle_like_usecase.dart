import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/news/domain/entities/like_result_entity.dart';
import 'package:click_seguro_app/modules/news/domain/repositories/news_repository.dart';
import 'package:fpdart/fpdart.dart';

class ToggleLikeUseCase {
  ToggleLikeUseCase(this._repository);

  final NewsRepository _repository;

  Future<Either<Failure, LikeResultEntity>> call(String newsId) =>
      _repository.toggleLike(newsId);
}
