import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alerts_snapshot.dart';
import 'package:click_seguro_app/modules/notifications/domain/repositories/notifications_repository.dart';
import 'package:fpdart/fpdart.dart';

class MarkAllAsReadUseCase {
  MarkAllAsReadUseCase(this._repository);

  final NotificationsRepository _repository;

  /// Sem não lidos, não grava (marcar de novo não muda nada).
  Future<Either<Failure, AlertsSnapshot>> call() async {
    return switch (await _repository.getSnapshot()) {
      Left(:final value) => Left(value),
      Right(:final value) => await _markAll(value),
    };
  }

  Future<Either<Failure, AlertsSnapshot>> _markAll(
    AlertsSnapshot snapshot,
  ) async {
    if (snapshot.unreadCount == 0) return Right(snapshot);
    final marked = snapshot.markAllRead();
    final saved = await _repository.saveSnapshot(marked);
    return saved.map((_) => marked);
  }
}
