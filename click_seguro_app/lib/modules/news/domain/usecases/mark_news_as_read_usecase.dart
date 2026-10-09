import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/news/domain/repositories/news_repository.dart';
import 'package:fpdart/fpdart.dart';

class MarkNewsAsReadUseCase {
  MarkNewsAsReadUseCase(this._repository);

  final NewsRepository _repository;

  Future<Either<Failure, Unit>> call(String newsId) =>
      _repository.markAsRead(newsId);
}
