import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alerts_snapshot.dart';
import 'package:click_seguro_app/modules/notifications/domain/repositories/notifications_repository.dart';
import 'package:fpdart/fpdart.dart';

class MarkAllAsReadUseCase {
  MarkAllAsReadUseCase(this._repository);

  final NotificationsRepository _repository;

  /// Lê o registro de novo antes de marcar. Com [newsIds], marca só esses (o
  /// que a pessoa viu na tela: um alerta que chegou por conferência depois
  /// continua novo, R5). Sem não lidos a marcar, não grava.
  Future<Either<Failure, AlertsSnapshot>> call({Set<String>? newsIds}) async {
    return switch (await _repository.getSnapshot()) {
      Left(:final value) => Left(value),
      Right(:final value) => await _markAll(value, newsIds),
    };
  }

  Future<Either<Failure, AlertsSnapshot>> _markAll(
    AlertsSnapshot snapshot,
    Set<String>? newsIds,
  ) async {
    final marked = newsIds == null
        ? snapshot.markAllRead()
        : newsIds.fold(snapshot, (current, id) => current.markRead(id));
    if (marked.unreadCount == snapshot.unreadCount) return Right(snapshot);
    final saved = await _repository.saveSnapshot(marked);
    return saved.map((_) => marked);
  }
}
