import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/achievement_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/news_counts_entity.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/area_state.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/profile_controller.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/profile_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../fakes/fake_profile_repository.dart';
import '../../fakes/profile_controller_factory.dart';

void main() {
  late FakeProfileRepository repository;
  late ProfileController controller;

  setUp(() {
    repository = FakeProfileRepository();
    controller = buildProfileController(repository);
  });

  NewsCountsEntity? countsOf(ProfileController c) => switch (c.counts) {
    AreaLoaded(:final value) => value,
    _ => null,
  };

  List<AchievementEntity>? achievementsOf(ProfileController c) =>
      switch (c.achievements) {
        AreaLoaded(:final value) => value,
        _ => null,
      };

  test('começa carregando', () {
    expect(controller.status, ProfileStatus.loading);
    expect(controller.counts, isA<AreaLoading<NewsCountsEntity>>());
  });

  test('load: perfil, números e conquistas', () async {
    await controller.load();

    expect(controller.status, ProfileStatus.loaded);
    expect(controller.profile, testProfile);
    expect(countsOf(controller), testCounts);
    expect(achievementsOf(controller), isNotEmpty);
  });

  test('os três pedidos saem juntos', () async {
    repository.profileGate = Completer<void>();

    final loading = controller.load();
    await Future<void>.delayed(Duration.zero);

    expect(repository.profileCalls, 1);
    expect(repository.countsCalls, 1);
    expect(repository.progressCalls, 1);
    repository.profileGate!.complete();
    await loading;
  });

  test('avisa loading e depois loaded', () async {
    final statuses = <ProfileStatus>[];
    controller.addListener(() => statuses.add(controller.status));

    await controller.load();

    expect(statuses.first, ProfileStatus.loading);
    expect(statuses.last, ProfileStatus.loaded);
  });

  test('perfil falha → error com a falha', () async {
    repository.profileResults[0] = const Left(ConnectionFailure());

    await controller.load();

    expect(controller.status, ProfileStatus.error);
    expect(controller.failure, isA<ConnectionFailure>());
  });

  test('números falham → counts e achievements failed, perfil ok', () async {
    repository.countsResults[0] = const Left(ServerFailure());

    await controller.load();

    expect(controller.status, ProfileStatus.loaded);
    expect(controller.profile, testProfile);
    expect(controller.counts, isA<AreaFailed<NewsCountsEntity>>());
    expect(controller.achievements, isA<AreaFailed<List<AchievementEntity>>>());
  });

  test('progresso falha → só achievements failed', () async {
    repository.progressResults[0] = const Left(ServerFailure());

    await controller.load();

    expect(countsOf(controller), testCounts);
    expect(controller.achievements, isA<AreaFailed<List<AchievementEntity>>>());
  });

  test('retryCounts recarrega só os números', () async {
    repository.countsResults
      ..[0] = const Left(ServerFailure())
      ..add(const Right(testCounts));
    await controller.load();

    await controller.retryCounts();

    expect(countsOf(controller), testCounts);
    expect(achievementsOf(controller), isNotEmpty);
    expect(repository.profileCalls, 1);
    expect(repository.progressCalls, 1);
    expect(repository.countsCalls, 2);
  });

  test('retryAchievements recarrega o progresso', () async {
    repository.progressResults
      ..[0] = const Left(ServerFailure())
      ..add(const Right(testProgress));
    await controller.load();

    await controller.retryAchievements();

    expect(achievementsOf(controller), isNotEmpty);
    expect(repository.profileCalls, 1);
    expect(repository.progressCalls, 2);
  });

  test('refresh não volta para loading e atualiza os números', () async {
    await controller.load();
    repository.countsResults[0] = const Right(
      NewsCountsEntity(read: 13, saved: 5, liked: 9),
    );
    final statuses = <ProfileStatus>[];
    controller.addListener(() => statuses.add(controller.status));

    await controller.refresh();

    expect(statuses, isNot(contains(ProfileStatus.loading)));
    expect(controller.counts, isNot(isA<AreaLoading<NewsCountsEntity>>()));
    expect(countsOf(controller)!.read, 13);
  });

  test('achievedCount e totalCount', () async {
    repository.countsResults[0] = const Right(
      NewsCountsEntity(read: 1, saved: 0, liked: 0),
    );

    await controller.load();

    // 6 fixas (há módulo com lições) + 1 do módulo; só Leitor atento.
    expect(controller.totalCount, 7);
    expect(controller.achievedCount, 1);
  });

  test('sem conquistas carregadas, contagens zeradas', () {
    expect(controller.totalCount, 0);
    expect(controller.achievedCount, 0);
  });

  test('dispose durante a carga não lança', () async {
    repository.profileGate = Completer<void>();
    final loading = controller.load();

    controller.dispose();
    repository.profileGate!.complete();

    await expectLater(loading, completes);
  });
}
