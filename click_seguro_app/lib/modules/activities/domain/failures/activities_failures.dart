import 'package:click_seguro_app/core/errors/failure.dart';
import 'package:click_seguro_app/core/i18n/app_strings.dart';

/// O módulo não existe mais no serviço (404 `EDUCATIONAL_MODULE_NOT_FOUND`).
class ModuleNotFoundFailure extends Failure {
  const ModuleNotFoundFailure() : super(AppStrings.activitiesModuleUnavailable);
}

/// O serviço recusou a resposta porque a pergunta mudou: alternativa que não
/// é da lição, lição ou módulo que sumiu (R5 de specs/018). A tela recarrega.
class AnswerRejectedFailure extends Failure {
  const AnswerRejectedFailure() : super(AppStrings.activitiesAnswerRejected);
}
