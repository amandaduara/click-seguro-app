import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/activities_dashboard_entity.dart';
import 'package:click_seguro_app/modules/activities/domain/usecases/get_activities_dashboard_usecase.dart';
import 'package:click_seguro_app/modules/activities/presentation/controller/activities_dashboard_status.dart';
import 'package:flutter/foundation.dart';

/// Estado do painel de atividades (data-model de specs/015-painel-atividades).
class ActivitiesDashboardController extends ChangeNotifier {
  ActivitiesDashboardController({
    required GetActivitiesDashboardUseCase getDashboard,
  }) : _getDashboard = getDashboard;

  final GetActivitiesDashboardUseCase _getDashboard;

  ActivitiesDashboardStatus _status = ActivitiesDashboardStatus.loading;
  ActivitiesDashboardStatus get status => _status;

  ActivitiesDashboardEntity? _dashboard;
  ActivitiesDashboardEntity? get dashboard => _dashboard;

  Failure? _failure;
  Failure? get failure => _failure;

  /// Numera as cargas: respostas de cargas anteriores são ignoradas.
  int _requestId = 0;
  bool _disposed = false;

  /// Carga inicial (ou "Tentar novamente").
  Future<void> load() async {
    final int request = ++_requestId;
    _status = ActivitiesDashboardStatus.loading;
    _failure = null;
    _notify();
    final result = await _getDashboard();
    if (_disposed || request != _requestId) return;
    result.fold(
      (failure) {
        _failure = failure;
        _status = ActivitiesDashboardStatus.error;
      },
      (dashboard) {
        _dashboard = dashboard;
        _status = dashboard.isEmpty
            ? ActivitiesDashboardStatus.empty
            : ActivitiesDashboardStatus.loaded;
      },
    );
    _notify();
  }

  /// Ao voltar para o painel (FR-006): sem "carregando"; se falhar, o
  /// conteúdo já mostrado fica (FR-011). Sem conteúdo, é uma carga normal.
  Future<void> refresh() async {
    if (_dashboard == null) return load();
    final int request = ++_requestId;
    final result = await _getDashboard();
    if (_disposed || request != _requestId) return;
    result.fold((_) {}, (dashboard) {
      _dashboard = dashboard;
      _status = dashboard.isEmpty
          ? ActivitiesDashboardStatus.empty
          : ActivitiesDashboardStatus.loaded;
    });
    _notify();
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
