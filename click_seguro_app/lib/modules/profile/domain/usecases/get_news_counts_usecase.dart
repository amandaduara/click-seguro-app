import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/news_counts_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/repositories/profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetNewsCountsUseCase {
  GetNewsCountsUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<Failure, NewsCountsEntity>> call() =>
      _repository.getNewsCounts();
}
