import 'package:click_seguro_app/modules/activities/data/models/activities_dashboard_model.dart';
import 'package:click_seguro_app/modules/activities/data/models/answer_result_model.dart';
import 'package:click_seguro_app/modules/activities/data/models/module_detail_model.dart';

/// Lança `ApiException`; o repositório converte em `Failure`.
abstract class ActivitiesRemoteDataSource {
  /// `GET /app/educational/modules`. Sem token, o visitante recebe o
  /// progresso zerado.
  Future<ActivitiesDashboardModel> getModules();

  /// `GET /app/educational/modules/{id}`: lições e progresso do módulo.
  Future<ModuleDetailModel> getModuleDetail(String moduleId);

  /// `POST …/lessons/{lessonId}/answer`: a correção da resposta (B3). A
  /// transferência das respostas do visitante à conta nova (B1) ignora o
  /// resultado.
  Future<AnswerResultModel> answerLesson({
    required String moduleId,
    required String lessonId,
    required String selectedOptionId,
  });
}
