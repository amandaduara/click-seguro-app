import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/news/domain/entities/saved_news_result.dart';
import 'package:click_seguro_app/modules/news/domain/repositories/news_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetSavedNewsUseCase {
  GetSavedNewsUseCase(this._repository);

  final NewsRepository _repository;

  Future<Either<Failure, SavedNewsResult>> call(int page) =>
      _repository.getSavedNews(page);
}
