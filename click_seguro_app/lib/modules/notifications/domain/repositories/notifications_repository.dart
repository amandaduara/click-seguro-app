import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alert_entity.dart';
import 'package:click_seguro_app/modules/notifications/domain/entities/alerts_snapshot.dart';
import 'package:fpdart/fpdart.dart';

abstract class NotificationsRepository {
  /// Registro da conta atual; sem registro, outro dono ou ilegível, um
  /// registro vazio (`lastCheckAt == null`). Só local.
  Future<Either<Failure, AlertsSnapshot>> getSnapshot();

  /// Grava o registro inteiro, numa escrita só. Só local.
  Future<Either<Failure, Unit>> saveSnapshot(AlertsSnapshot snapshot);

  /// Notícias publicadas desde [since], no máximo [limit]; item inválido é
  /// ignorado.
  Future<Either<Failure, List<AlertEntity>>> fetchNewAlerts({
    required DateTime since,
    required int limit,
  });

  /// Valor atual de "Receber alertas" no serviço.
  Future<Either<Failure, bool>> getReceiveAlerts();

  /// Apaga o registro (sair da conta). Só local.
  Future<Either<Failure, Unit>> clear();
}
