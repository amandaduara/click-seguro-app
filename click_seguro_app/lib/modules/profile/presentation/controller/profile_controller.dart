import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/profile/domain/achievements_calculator.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/achievement_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/activity_progress_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/news_counts_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/entities/profile_entity.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/get_activity_progress_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/get_news_counts_usecase.dart';
import 'package:click_seguro_app/modules/profile/domain/usecases/get_profile_usecase.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/area_state.dart';
import 'package:click_seguro_app/modules/profile/presentation/controller/profile_status.dart';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

/// Estado da aba Perfil (data-model de specs/012-perfil). Perfil, números e
/// progresso são pedidos juntos; números e conquistas falham sozinhos (R2).
class ProfileController extends ChangeNotifier {
  ProfileController({
    required GetProfileUseCase getProfile,
    required GetNewsCountsUseCase getNewsCounts,
    required GetActivityProgressUseCase getActivityProgress,
  }) : _getProfile = getProfile,
       _getNewsCounts = getNewsCounts,
       _getActivityProgress = getActivityProgress;

  final GetProfileUseCase _getProfile;
  final GetNewsCountsUseCase _getNewsCounts;
  final GetActivityProgressUseCase _getActivityProgress;

  ProfileStatus _status = ProfileStatus.loading;
  ProfileStatus get status => _status;

  Failure? _failure;

  /// Por que o perfil não carregou ([ProfileStatus.error]).
  Failure? get failure => _failure;

  ProfileEntity? _profile;
  ProfileEntity? get profile => _profile;

  AreaState<NewsCountsEntity> _counts = const AreaLoading();
  AreaState<NewsCountsEntity> get counts => _counts;

  /// Último resultado do progresso: as conquistas precisam dele e das lidas.
  Either<Failure, ActivityProgressEntity>? _progress;

  AreaState<List<AchievementEntity>> _achievements = const AreaLoading();
  AreaState<List<AchievementEntity>> get achievements => _achievements;

  int get achievedCount => switch (_achievements) {
    AreaLoaded(:final value) => value.where((a) => a.achieved).length,
    _ => 0,
  };

  int get totalCount => switch (_achievements) {
    AreaLoaded(:final value) => value.length,
    _ => 0,
  };

  /// Sobe a cada busca: a resposta de uma busca antiga é descartada.
  int _generation = 0;
  bool _disposed = false;

  /// Primeira carga, ou de novo depois do erro: mostra o carregando.
  Future<void> load() {
    _status = ProfileStatus.loading;
    _counts = const AreaLoading();
    _achievements = const AreaLoading();
    _notify();
    return _fetch(profile: true, counts: true, progress: true);
  }

  /// Ao voltar à aba (FR-007, R4): busca tudo sem trocar a tela pelo
  /// carregando; os números mudam no lugar.
  Future<void> refresh() => _fetch(profile: true, counts: true, progress: true);

  Future<void> retryCounts() {
    _counts = const AreaLoading();
    _notify();
    return _fetch(profile: false, counts: true, progress: false);
  }

  /// Também busca os números se foram eles que falharam.
  Future<void> retryAchievements() {
    final bool countsFailed = _counts is AreaFailed<NewsCountsEntity>;
    _achievements = const AreaLoading();
    if (countsFailed) _counts = const AreaLoading();
    _notify();
    return _fetch(profile: false, counts: countsFailed, progress: true);
  }

  Future<void> _fetch({
    required bool profile,
    required bool counts,
    required bool progress,
  }) async {
    final int generation = ++_generation;
    final (profileResult, countsResult, progressResult) = await (
      profile ? _getProfile() : Future<Either<Failure, ProfileEntity>?>.value(),
      counts
          ? _getNewsCounts()
          : Future<Either<Failure, NewsCountsEntity>?>.value(),
      progress
          ? _getActivityProgress()
          : Future<Either<Failure, ActivityProgressEntity>?>.value(),
    ).wait;
    if (_disposed || generation != _generation) return;

    profileResult?.fold(
      (failure) {
        _failure = failure;
        _status = ProfileStatus.error;
      },
      (loaded) {
        _profile = loaded;
        _failure = null;
        _status = ProfileStatus.loaded;
      },
    );
    if (countsResult != null) {
      _counts = countsResult.fold(AreaFailed.new, AreaLoaded.new);
    }
    if (progressResult != null) _progress = progressResult;
    _achievements = _buildAchievements();
    _notify();
  }

  AreaState<List<AchievementEntity>> _buildAchievements() {
    final AreaState<NewsCountsEntity> counts = _counts;
    final Either<Failure, ActivityProgressEntity>? progress = _progress;
    if (counts is AreaFailed<NewsCountsEntity>) {
      return AreaFailed(counts.failure);
    }
    if (counts is! AreaLoaded<NewsCountsEntity> || progress == null) {
      return const AreaLoading();
    }
    return progress.fold(
      AreaFailed.new,
      (loaded) => AreaLoaded(
        AchievementsCalculator.build(
          readCount: counts.value.read,
          progress: loaded,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
