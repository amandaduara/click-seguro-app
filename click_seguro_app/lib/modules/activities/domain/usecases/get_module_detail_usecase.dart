import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_detail_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/repositories/activities_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetModuleDetailUseCase {
  const GetModuleDetailUseCase(this._repository);

  final ActivitiesRepository _repository;

  Future<Either<Failure, ModuleDetailEntity>> call(String moduleId) =>
      _repository.getModuleDetail(moduleId);
}
