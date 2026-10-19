import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/activities/data/datasources/activities_remote_data_source.dart';
import 'package:click_seguro_app/modules/activities/data/datasources/guest_progress_store.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/activities_dashboard_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/guest_answer.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/module_summary_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/repositories/activities_repository.dart';
import 'package:click_seguro_app/modules/common/api_client/api_client.dart';
import 'package:click_seguro_app/modules/common/api_client/api_failure_mapper.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:fpdart/fpdart.dart';

class ActivitiesRepositoryImpl implements ActivitiesRepository {
  ActivitiesRepositoryImpl(this._remote, this._store, this._session);

  /// Conteúdo que mudou no serviço: reenviar não adianta (R5).
  static const Set<String> _goneCodes = {
    'EDUCATIONAL_MODULE_NOT_FOUND',
    'EDUCATIONAL_LESSON_NOT_FOUND',
  };
  static const int _badRequest = 400;

  final ActivitiesRemoteDataSource _remote;
  final GuestProgressStore _store;
  final UserSessionService _session;

  /// Envio em andamento: os dois caminhos (logo depois do cadastro e na
  /// carga do painel) reaproveitam o mesmo, sem repetir respostas.
  Future<void>? _syncing;

  @override
  Future<Either<Failure, ActivitiesDashboardEntity>> getDashboard() async {
    final bool authenticated = _session.isAuthenticated;
    if (authenticated) await syncGuestAnswers();
    try {
      final dashboard = (await _remote.getModules()).toEntity();
      return Right(authenticated ? dashboard : _withSessionProgress(dashboard));
    } on ApiException catch (e) {
      return Left(e.toFailure());
    }
  }

  /// Uma resposta por vez; o que falhar fica para a próxima carga.
  @override
  Future<void> syncGuestAnswers() =>
      _syncing ??= _sendPending().whenComplete(() => _syncing = null);

  Future<void> _sendPending() async {
    for (final GuestAnswer answer in _store.pendingTransfer) {
      try {
        await _remote.answerLesson(
          moduleId: answer.moduleId,
          lessonId: answer.lessonId,
          selectedOptionId: answer.selectedOptionId,
        );
        _store.removePending(answer);
      } on ApiException catch (e) {
        if (_goneCodes.contains(e.errorCode) || e.statusCode == _badRequest) {
          _store.removePending(answer);
        }
      }
    }
  }

  /// Sem conta (visitante ou sessão expirada), o serviço manda o progresso
  /// zerado: vale o registro da sessão (RN-006).
  ActivitiesDashboardEntity _withSessionProgress(
    ActivitiesDashboardEntity dashboard,
  ) {
    final List<ModuleSummaryEntity> modules = [
      for (final ModuleSummaryEntity module in dashboard.modules)
        module.withCompletedCount(_store.answeredCount(module.id)),
    ];
    return ActivitiesDashboardEntity(
      modules: modules,
      totalCompleted: modules.fold(0, (sum, m) => sum + m.completedCount),
      totalAvailable: dashboard.totalAvailable,
    );
  }
}
