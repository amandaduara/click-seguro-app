import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/activities/domain/usecases/get_activities_dashboard_usecase.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/activities_dashboard_controller.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/activities_dashboard_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../fakes/activities_fixtures.dart';
import '../../fakes/fake_activities_repository.dart';

void main() {
  late FakeActivitiesRepository repository;
  late ActivitiesDashboardController controller;

  ActivitiesDashboardController build() => ActivitiesDashboardController(
    getDashboard: GetActivitiesDashboardUseCase(repository),
  );

  setUp(() {
    repository = FakeActivitiesRepository();
    controller = build();
  });

  test('começa carregando', () {
    expect(controller.status, ActivitiesDashboardStatus.loading);
    expect(controller.dashboard, isNull);
  });

  test('módulos → loaded com o painel', () async {
    await controller.load();

    expect(controller.status, ActivitiesDashboardStatus.loaded);
    expect(controller.dashboard!.modules, hasLength(3));
  });

  test('nenhum módulo → empty', () async {
    repository = FakeActivitiesRepository([Right(dashboard(modules: []))]);
    controller = build();

    await controller.load();

    expect(controller.status, ActivitiesDashboardStatus.empty);
  });

  test('falha → error com a falha; load de novo recupera', () async {
    repository = FakeActivitiesRepository([
      const Left(ConnectionFailure()),
      Right(dashboard()),
    ]);
    controller = build();

    await controller.load();
    expect(controller.status, ActivitiesDashboardStatus.error);
    expect(controller.failure, isA<ConnectionFailure>());

    final Future<void> retry = controller.load();
    expect(controller.status, ActivitiesDashboardStatus.loading);
    await retry;
    expect(controller.status, ActivitiesDashboardStatus.loaded);
    expect(controller.failure, isNull);
  });

  group('refresh', () {
    test('com conteúdo: não passa por loading e troca o painel', () async {
      repository = FakeActivitiesRepository([
        Right(dashboard()),
        Right(dashboard(modules: threeModulesJson(m1: 1))),
      ]);
      controller = build();
      await controller.load();
      final List<ActivitiesDashboardStatus> seen = [];
      controller.addListener(() => seen.add(controller.status));

      await controller.refresh();

      expect(seen, isNot(contains(ActivitiesDashboardStatus.loading)));
      expect(controller.dashboard!.modules.first.completedCount, 1);
    });

    test('falha mantém o painel anterior', () async {
      repository = FakeActivitiesRepository([
        Right(dashboard()),
        const Left(ConnectionFailure()),
      ]);
      controller = build();
      await controller.load();

      await controller.refresh();

      expect(controller.status, ActivitiesDashboardStatus.loaded);
      expect(controller.dashboard!.modules, hasLength(3));
    });

    test('sem conteúdo: como load()', () async {
      repository = FakeActivitiesRepository([
        const Left(ConnectionFailure()),
        Right(dashboard()),
      ]);
      controller = build();
      await controller.load();

      final Future<void> refreshing = controller.refresh();
      expect(controller.status, ActivitiesDashboardStatus.loading);
      await refreshing;

      expect(controller.status, ActivitiesDashboardStatus.loaded);
    });
  });

  test('dispose durante a carga não lança', () async {
    repository.gate = Completer<void>();
    final Future<void> loading = controller.load();

    controller.dispose();
    repository.gate!.complete();

    await expectLater(loading, completes);
  });
}
