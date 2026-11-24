import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/news/domain/repositories/news_repository.dart';
import 'package:fpdart/fpdart.dart';

class ToggleSaveUseCase {
  ToggleSaveUseCase(this._repository);

  final NewsRepository _repository;

  Future<Either<Failure, bool>> call(String newsId) =>
      _repository.toggleSave(newsId);
}
