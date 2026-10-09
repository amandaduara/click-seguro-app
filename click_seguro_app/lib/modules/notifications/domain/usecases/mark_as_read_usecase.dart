import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alerts_snapshot.dart';
import 'package:click_seguro_app/modules/notifications/domain/repositories/notifications_repository.dart';
import 'package:fpdart/fpdart.dart';

class MarkAsReadUseCase {
  MarkAsReadUseCase(this._repository);

  final NotificationsRepository _repository;

  /// Lê o registro de novo antes de marcar, para não desfazer o que uma
  /// conferência acabou de gravar. Sem nada a mudar, não grava.
  Future<Either<Failure, AlertsSnapshot>> call(String newsId) async {
    return switch (await _repository.getSnapshot()) {
      Left(:final value) => Left(value),
      Right(:final value) => await _mark(value, newsId),
    };
  }

  Future<Either<Failure, AlertsSnapshot>> _mark(
    AlertsSnapshot snapshot,
    String newsId,
  ) async {
    final marked = snapshot.markRead(newsId);
    if (marked.unreadCount == snapshot.unreadCount) return Right(snapshot);
    final saved = await _repository.saveSnapshot(marked);
    return saved.map((_) => marked);
  }
}
