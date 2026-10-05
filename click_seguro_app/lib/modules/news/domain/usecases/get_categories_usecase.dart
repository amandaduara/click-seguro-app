import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_category_entity.dart';
import 'package:click_seguro_app/modules/news/domain/repositories/news_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetCategoriesUseCase {
  GetCategoriesUseCase(this._repository);

  final NewsRepository _repository;

  Future<Either<Failure, List<NewsCategoryEntity>>> call() =>
      _repository.getCategories();
}
