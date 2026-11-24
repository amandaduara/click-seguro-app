import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/news/domain/entities/reels_page_entity.dart';
import 'package:click_seguro_app/modules/news/domain/repositories/news_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetReelsUseCase {
  GetReelsUseCase(this._repository);

  final NewsRepository _repository;

  Future<Either<Failure, ReelsPageEntity>> call({String? cursor}) =>
      _repository.getReels(cursor: cursor);
}
