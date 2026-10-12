import 'dart:async';

import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/activity_progress_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/news_counts_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_update.dart';
import 'package:click_seguro_app/modules/profile/domain/repositories/profile_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Perfil de teste, sem telefone nem foto.
const ProfileEntity testProfile = ProfileEntity(
  name: 'Maria da Silva',
  email: 'maria@exemplo.com',
);

const NewsCountsEntity testCounts = NewsCountsEntity(
  read: 12,
  saved: 5,
  liked: 9,
);

/// Um módulo de 3 lições, não começado.
const ActivityProgressEntity testProgress = ActivityProgressEntity(
  modules: [
    ModuleProgressEntity(
      title: 'Golpes Digitais',
      order: 1,
      lessonsCount: 3,
      completedCount: 0,
    ),
  ],
  lessonsCompleted: 0,
);

/// Repository em memória: cada método tem uma fila de respostas (a última se
/// repete) e um `Completer` opcional para segurar a resposta.
class FakeProfileRepository implements ProfileRepository {
  final List<Either<Failure, ProfileEntity>> profileResults = [
    const Right(testProfile),
  ];
  final List<Either<Failure, NewsCountsEntity>> countsResults = [
    const Right(testCounts),
  ];
  final List<Either<Failure, ActivityProgressEntity>> progressResults = [
    const Right(testProgress),
  ];
  final List<Either<Failure, Unit>> updateResults = [const Right(unit)];
  final List<Either<Failure, String>> uploadResults = [
    const Right('https://img.test/nova.png'),
  ];
  final List<Either<Failure, Unit>> removeResults = [const Right(unit)];

  Completer<void>? profileGate;
  Completer<void>? countsGate;
  Completer<void>? progressGate;
  Completer<void>? updateGate;
  Completer<void>? uploadGate;
  Completer<void>? removeGate;

  int profileCalls = 0;
  int countsCalls = 0;
  int progressCalls = 0;
  final List<ProfileUpdate> updateCalls = [];
  final List<String> uploadCalls = [];
  int removeCalls = 0;

  int get totalCalls =>
      profileCalls +
      countsCalls +
      progressCalls +
      updateCalls.length +
      uploadCalls.length +
      removeCalls;

  T _next<T>(List<T> queue) =>
      queue.length > 1 ? queue.removeAt(0) : queue.first;

  Future<T> _answer<T>(List<T> queue, Completer<void>? gate) async {
    final T result = _next(queue);
    await gate?.future;
    return result;
  }

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() {
    profileCalls++;
    return _answer(profileResults, profileGate);
  }

  @override
  Future<Either<Failure, NewsCountsEntity>> getNewsCounts() {
    countsCalls++;
    return _answer(countsResults, countsGate);
  }

  @override
  Future<Either<Failure, ActivityProgressEntity>> getActivityProgress() {
    progressCalls++;
    return _answer(progressResults, progressGate);
  }

  @override
  Future<Either<Failure, Unit>> updateProfile(ProfileUpdate update) {
    updateCalls.add(update);
    return _answer(updateResults, updateGate);
  }

  @override
  Future<Either<Failure, String>> uploadAvatar(String filePath) {
    uploadCalls.add(filePath);
    return _answer(uploadResults, uploadGate);
  }

  @override
  Future<Either<Failure, Unit>> removeAvatar() {
    removeCalls++;
    return _answer(removeResults, removeGate);
  }
}
