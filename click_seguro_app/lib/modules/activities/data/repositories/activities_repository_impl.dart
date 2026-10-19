import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/activities/data/datasources/activities_remote_data_source.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/activities_dashboard_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/repositories/activities_repository.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/api_client/api_failure_mapper.dart';
import 'package:fpdart/fpdart.dart';

class ActivitiesRepositoryImpl implements ActivitiesRepository {
  ActivitiesRepositoryImpl(this._remote);

  final ActivitiesRemoteDataSource _remote;

  @override
  Future<Either<Failure, ActivitiesDashboardEntity>> getDashboard() async {
    try {
      final model = await _remote.getModules();
      return Right(model.toEntity());
    } on ApiException catch (e) {
      return Left(e.toFailure());
    }
  }
}
