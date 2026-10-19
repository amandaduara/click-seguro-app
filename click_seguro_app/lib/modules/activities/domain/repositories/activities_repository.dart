import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/modules/activities/domain/entities/activities_dashboard_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class ActivitiesRepository {
  /// Módulos e progresso: da conta pelo serviço; sem conta, do registro da
  /// sessão (RN-006).
  Future<Either<Failure, ActivitiesDashboardEntity>> getDashboard();

  /// Envia à conta recém-criada o progresso que o visitante fez na sessão
  /// (FR-008a). Nunca falha para quem chama.
  Future<void> syncGuestAnswers();
}
