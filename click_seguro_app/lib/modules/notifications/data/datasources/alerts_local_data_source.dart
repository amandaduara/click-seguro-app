import 'package:click_seguro_app/modules/notifications/data/models/alerts_snapshot_model.dart';

abstract class AlertsLocalDataSource {
  /// Registro do dono atual; sem registro, de outro dono ou sem dono, `null`.
  /// Armazenamento que falha lança.
  Future<AlertsSnapshotModel?> read();

  /// Grava o registro inteiro, com o dono atual, numa escrita só.
  Future<void> write(AlertsSnapshotModel snapshot);

  /// Apaga o registro.
  Future<void> clear();
}
