import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';

/// Falha genérica da API (5xx, 4xx sem tratamento específico, resposta
/// malformada). Features podem estender para cenários que a UI precisa
/// distinguir (ex.: `class NewsNotFoundFailure extends ServerFailure`).
class ServerFailure extends Failure {
  const ServerFailure([super.message = AppStrings.errorGeneric]);
}
