import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alerts_snapshot.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/check_new_alerts_result.dart';
import 'package:click_seguro_app/modules/notifications/domain/repositories/notifications_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Confere o serviço atrás de notícias publicadas depois da última conferência
/// e cria um alerta para cada uma (data-model de specs/011-alertas-locais).
/// Falha em qualquer passo: devolve a falha e não grava nada (FR-005).
class CheckNewAlertsUseCase {
  CheckNewAlertsUseCase(this._repository);

  /// Notícias pedidas ao serviço, igual ao teto de alertas (R6).
  static const int checkLimit = AlertsSnapshot.maxAlerts;

  final NotificationsRepository _repository;

  /// [now] é o início da conferência: vira a nova última conferência.
  Future<Either<Failure, CheckNewAlertsResult>> call(DateTime now) async {
    switch (await _repository.getSnapshot()) {
      case Left(:final value):
        return Left(value);
      case Right(value: final snapshot):
        final lastCheckAt = snapshot.lastCheckAt;
        if (lastCheckAt == null) return _firstRun(snapshot, now);
        return switch (await _repository.getReceiveAlerts()) {
          Left(:final value) => Left(value),
          Right(value: true) => await _check(lastCheckAt, now),
          Right(value: false) => await _disabled(now),
        };
    }
  }

  Future<Either<Failure, CheckNewAlertsResult>> _firstRun(
    AlertsSnapshot snapshot,
    DateTime now,
  ) => _save(snapshot.copyWith(lastCheckAt: now), CheckOutcome.firstRun);

  Future<Either<Failure, CheckNewAlertsResult>> _disabled(DateTime now) async {
    return switch (await _repository.getSnapshot()) {
      Left(:final value) => Left(value),
      Right(:final value) => await _save(
        value.copyWith(lastCheckAt: now, receiveAlerts: false),
        CheckOutcome.disabled,
      ),
    };
  }

  Future<Either<Failure, CheckNewAlertsResult>> _check(
    DateTime lastCheckAt,
    DateTime now,
  ) async {
    final retentionStart = now.subtract(
      const Duration(days: AlertsSnapshot.retentionDays),
    );
    final since = lastCheckAt.isAfter(retentionStart)
        ? lastCheckAt
        : retentionStart;
    return switch (await _repository.fetchNewAlerts(
      since: since,
      limit: checkLimit,
    )) {
      Left(:final value) => Left(value),
      Right(:final value) => await _merge(value, lastCheckAt, now),
    };
  }

  Future<Either<Failure, CheckNewAlertsResult>> _merge(
    List<AlertEntity> candidates,
    DateTime lastCheckAt,
    DateTime now,
  ) async {
    // Lê de novo: o que foi marcado durante o pedido não pode se perder (R5).
    return switch (await _repository.getSnapshot()) {
      Left(:final value) => Left(value),
      Right(:final value) => await _save(
        value
            .merge(_newOnes(candidates, since: lastCheckAt), now)
            .copyWith(lastCheckAt: now, receiveAlerts: true),
        CheckOutcome.updated,
      ),
    };
  }

  /// Rede de segurança do filtro do serviço: só o publicado depois de [since].
  List<AlertEntity> _newOnes(
    List<AlertEntity> candidates, {
    required DateTime since,
  }) => [
    for (final alert in candidates)
      if (alert.publishedAt.isAfter(since)) alert,
  ];

  Future<Either<Failure, CheckNewAlertsResult>> _save(
    AlertsSnapshot snapshot,
    CheckOutcome outcome,
  ) async {
    final saved = await _repository.saveSnapshot(snapshot);
    return saved.map(
      (_) => CheckNewAlertsResult(snapshot: snapshot, outcome: outcome),
    );
  }
}
