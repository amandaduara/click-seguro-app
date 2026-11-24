import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/activities_dashboard_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/repositories/activities_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetActivitiesDashboardUseCase {
  const GetActivitiesDashboardUseCase(this._repository);

  final ActivitiesRepository _repository;

  Future<Either<Failure, ActivitiesDashboardEntity>> call() =>
      _repository.getDashboard();
}
