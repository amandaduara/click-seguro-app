import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/settings/domain/entities/account_summary_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class AccountRepository {
  Future<Either<Failure, AccountSummaryEntity>> getAccount();

  Future<Either<Failure, Unit>> setReceiveAlerts(bool value);

  /// Troca a senha e entra de novo com ela, para a pessoa continuar
  /// conectada (o serviço revoga a renovação, R0 de specs/013).
  Future<Either<Failure, Unit>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
