import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/news/domain/entities/news_detail_entity.dart';
import 'package:click_seguro_app/modules/news/domain/repositories/news_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetNewsDetailUseCase {
  GetNewsDetailUseCase(this._repository);

  final NewsRepository _repository;

  Future<Either<Failure, NewsDetailResult>> call(String id) =>
      _repository.getNewsDetail(id);
}
