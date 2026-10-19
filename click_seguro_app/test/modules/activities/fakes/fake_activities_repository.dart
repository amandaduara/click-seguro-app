import 'dart:async';

import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/activities/data/models/activities_dashboard_model.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/activities_dashboard_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/repositories/activities_repository.dart';
import 'package:fpdart/fpdart.dart';

import 'activities_fixtures.dart';

/// Painel em memória: [results] é uma fila (o último se repete); [gate]
/// segura a próxima resposta até completar.
class FakeActivitiesRepository implements ActivitiesRepository {
  FakeActivitiesRepository([
    List<Either<Failure, ActivitiesDashboardEntity>>? results,
  ]) : results = results ?? [Right(dashboard())];

  final List<Either<Failure, ActivitiesDashboardEntity>> results;
  Completer<void>? gate;
  int calls = 0;

  @override
  Future<Either<Failure, ActivitiesDashboardEntity>> getDashboard() async {
    calls++;
    await gate?.future;
    return results.length > 1 ? results.removeAt(0) : results.single;
  }
}

/// Painel a partir do JSON das fixtures (os três módulos, por padrão).
ActivitiesDashboardEntity dashboard({
  List<Map<String, dynamic>>? modules,
  int? totalLessonsCompleted,
  int? totalLessonsAvailable,
}) => ActivitiesDashboardModel.fromJson(
  dashboardJson(
    modules: modules,
    totalLessonsCompleted: totalLessonsCompleted,
    totalLessonsAvailable: totalLessonsAvailable,
  ),
).toEntity();
