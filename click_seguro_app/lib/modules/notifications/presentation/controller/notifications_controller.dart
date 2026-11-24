import 'dart:async';

import 'package:click_seguro_app/core/errors/errors.dart';
import 'package:click_seguro_app/modules/common/services/user_session_service.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alerts_snapshot.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/check_new_alerts_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/clear_alerts_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/get_alerts_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/mark_all_as_read_usecase.dart';
import 'package:click_seguro_app/modules/notifications/domain/usecases/mark_as_read_usecase.dart';
import 'package:click_seguro_app/modules/notifications/presentation/controller/alerts_status.dart';
import 'package:flutter/foundation.dart';

/// Estado dos alertas da conta, um só para o app (data-model de
/// specs/011-alertas-locais): vive acima das telas porque o contador do sino
/// aparece em três abas. Visitante e desconectado nunca chegam ao repository.
///
/// Tudo o que grava passa por uma fila (R5). Como a conferência traz o pedido
/// e a mesclagem num só usecase, ela entra inteira na fila; o que a pessoa
/// marcar como lido enquanto isso fica em [_pendingReads] e é reaplicado
/// quando o resultado chega.
class NotificationsController extends ChangeNotifier {
  NotificationsController({
    required CheckNewAlertsUseCase checkNewAlerts,
    required GetAlertsUseCase getAlerts,
    required MarkAsReadUseCase markAsRead,
    required MarkAllAsReadUseCase markAllAsRead,
    required ClearAlertsUseCase clearAlerts,
    required ValueListenable<UserSessionStatus> sessionStatus,
    DateTime Function()? now,
  }) : _checkNewAlerts = checkNewAlerts,
       _getAlerts = getAlerts,
       _markAsRead = markAsRead,
       _markAllAsRead = markAllAsRead,
       _clearAlerts = clearAlerts,
       _sessionStatus = sessionStatus,
       _now = now ?? DateTime.now {
    _sessionStatus.addListener(_onSessionChanged);
  }

  /// Conferência automática: no mínimo este tempo depois da anterior (R2).
  static const Duration autoCheckInterval = Duration(minutes: 5);

  final CheckNewAlertsUseCase _checkNewAlerts;
  final GetAlertsUseCase _getAlerts;
  final MarkAsReadUseCase _markAsRead;
  final MarkAllAsReadUseCase _markAllAsRead;
  final ClearAlertsUseCase _clearAlerts;
  final ValueListenable<UserSessionStatus> _sessionStatus;
  final DateTime Function() _now;

  /// "Agora" do controller (injetável): a tela agrupa os alertas com ele.
  DateTime get now => _now();

  AlertsStatus _status = AlertsStatus.loading;
  AlertsStatus get status => _status;

  AlertsSnapshot _snapshot = const AlertsSnapshot();

  /// Do mais novo ao mais antigo; vazio sem conta.
  List<AlertEntity> get alerts => _snapshot.alerts;

  int get unreadCount => _snapshot.unreadCount;

  /// Último valor de "Receber alertas" visto no serviço; `null`, desconhecido.
  bool? get receiveAlerts => _snapshot.receiveAlerts;

  bool _isChecking = false;

  /// Só impede conferência dupla: nenhuma tela mostra indicador.
  bool get isChecking => _isChecking;

  Failure? _lastCheckFailure;

  /// Só [ConnectionFailure]: as outras falhas são silenciosas (FR-005).
  Failure? get lastCheckFailure => _lastCheckFailure;

  DateTime? _lastAutoCheckStartedAt;
  DateTime? get lastAutoCheckStartedAt => _lastAutoCheckStartedAt;

  /// Marcados como lido na tela e ainda não gravados.
  final Set<String> _pendingReads = {};

  /// Sobe a cada mudança de sessão: o que estava no ar é descartado.
  int _generation = 0;
  Future<void> _queue = Future<void>.value();
  bool _disposed = false;

  bool get _hasAccount =>
      _sessionStatus.value == UserSessionStatus.authenticated;

  /// Lê o registro da conta. Sem conta, deixa o estado vazio.
  Future<void> load() async {
    if (!_hasAccount) {
      _reset();
      return;
    }
    final int generation = _generation;
    await _enqueue(() async {
      final result = await _getAlerts();
      if (_disposed || generation != _generation) return;
      result.fold((_) {}, (loaded) => _snapshot = _withPendingReads(loaded));
      _status = AlertsStatus.ready;
      _notify();
    });
  }

  /// Confere as notícias novas. Automática ([force] falso): ignorada dentro de
  /// [autoCheckInterval] da anterior; nenhuma roda durante outra.
  Future<void> checkNew({bool force = false}) async {
    if (!_hasAccount || _isChecking) return;
    final DateTime started = _now();
    final DateTime? last = _lastAutoCheckStartedAt;
    if (!force &&
        last != null &&
        started.difference(last) < autoCheckInterval) {
      return;
    }
    _isChecking = true;
    _lastAutoCheckStartedAt = started;
    final int generation = _generation;
    await _enqueue(() async {
      final result = await _checkNewAlerts(started);
      if (_disposed || generation != _generation) return;
      result.fold(
        (failure) =>
            _lastCheckFailure = failure is ConnectionFailure ? failure : null,
        (checked) {
          _lastCheckFailure = null;
          _snapshot = _withPendingReads(checked.snapshot);
        },
      );
    });
    if (generation == _generation) _isChecking = false;
    _notify();
  }

  /// Marca na hora, em memória, e grava depois. Id inexistente ou já lido:
  /// nada acontece. Falha ao gravar mantém o estado em memória.
  Future<void> markAsRead(String newsId) async {
    if (!_hasAccount) return;
    final bool unread = _snapshot.alerts.any(
      (alert) => alert.newsId == newsId && !alert.isRead,
    );
    if (!unread) return;
    _snapshot = _snapshot.markRead(newsId);
    _pendingReads.add(newsId);
    _notify();
    final int generation = _generation;
    await _enqueue(() async {
      if (_disposed || generation != _generation) return;
      await _markAsRead(newsId);
      _pendingReads.remove(newsId);
    });
  }

  /// Marca na hora, em memória, os alertas que a tela mostra e grava depois
  /// só esses: o que chegar por conferência no meio continua novo (R5).
  Future<void> markAllAsRead() async {
    if (!_hasAccount) return;
    final Set<String> unreadIds = {
      for (final alert in _snapshot.alerts)
        if (!alert.isRead) alert.newsId,
    };
    if (unreadIds.isEmpty) return;
    _snapshot = _snapshot.markAllRead();
    _pendingReads.addAll(unreadIds);
    _notify();
    final int generation = _generation;
    await _enqueue(() async {
      if (_disposed || generation != _generation) return;
      await _markAllAsRead(newsIds: unreadIds);
      _pendingReads.removeAll(unreadIds);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _sessionStatus.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    _generation++;
    _isChecking = false;
    _lastAutoCheckStartedAt = null;
    switch (_sessionStatus.value) {
      case UserSessionStatus.authenticated:
        _reset(status: AlertsStatus.loading);
        unawaited(load());
      case UserSessionStatus.guest:
        _reset();
      case UserSessionStatus.unauthenticated:
        _reset();
        unawaited(
          _enqueue(() async {
            await _clearAlerts();
          }),
        );
    }
  }

  void _reset({AlertsStatus status = AlertsStatus.ready}) {
    _snapshot = const AlertsSnapshot();
    _pendingReads.clear();
    _lastCheckFailure = null;
    _status = status;
    _notify();
  }

  AlertsSnapshot _withPendingReads(AlertsSnapshot snapshot) {
    var marked = snapshot;
    for (final String id in _pendingReads) {
      marked = marked.markRead(id);
    }
    return marked;
  }

  /// Uma gravação de cada vez, na ordem em que foram pedidas.
  Future<void> _enqueue(Future<void> Function() task) {
    final Future<void> next = _queue.then((_) => task());
    _queue = next.then((_) {}, onError: (Object _) {});
    return next;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
